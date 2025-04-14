-- Criar tabela de tipos de status
CREATE TABLE "StatusType" (
    "id" SERIAL NOT NULL,
    "name" VARCHAR(50) NOT NULL,
    "category" VARCHAR(50) NOT NULL,

    CONSTRAINT "StatusType_pkey" PRIMARY KEY ("id")
);

-- Criar índice único em nome do tipo de status
CREATE UNIQUE INDEX "StatusType_name_key" ON "StatusType"("name");

-- Criar tabela de localizações da empresa
CREATE TABLE "CompanyLocation" (
    "id" SERIAL NOT NULL,
    "company_id" INTEGER NOT NULL,
    "city" VARCHAR(100) NOT NULL,
    "state" VARCHAR(50),
    "country" VARCHAR(50) NOT NULL,
    "is_remote" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "CompanyLocation_pkey" PRIMARY KEY ("id")
);

-- Criar índices para CompanyLocation
CREATE INDEX "CompanyLocation_company_id_idx" ON "CompanyLocation"("company_id");
CREATE INDEX "CompanyLocation_city_idx" ON "CompanyLocation"("city");
CREATE INDEX "CompanyLocation_is_remote_idx" ON "CompanyLocation"("is_remote");

-- Adicionar chave estrangeira para CompanyLocation
ALTER TABLE "CompanyLocation" ADD CONSTRAINT "CompanyLocation_company_id_fkey" FOREIGN KEY ("company_id") REFERENCES "Company"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Criar tabela de detalhes da posição
CREATE TABLE "PositionDetails" (
    "id" SERIAL NOT NULL,
    "position_id" INTEGER NOT NULL,
    "description" TEXT,
    "job_description" TEXT,
    "requirements" TEXT,
    "responsibilities" TEXT,
    "company_description" TEXT,
    "application_deadline" DATE,
    "contact_info" VARCHAR(255),

    CONSTRAINT "PositionDetails_pkey" PRIMARY KEY ("id")
);

-- Criar índices para PositionDetails
CREATE UNIQUE INDEX "PositionDetails_position_id_key" ON "PositionDetails"("position_id");
CREATE INDEX "PositionDetails_position_id_idx" ON "PositionDetails"("position_id");
CREATE INDEX "PositionDetails_application_deadline_idx" ON "PositionDetails"("application_deadline");

-- Criar tabela de salários das posições
CREATE TABLE "PositionSalary" (
    "id" SERIAL NOT NULL,
    "position_id" INTEGER NOT NULL,
    "salary_min" DECIMAL(10,2),
    "salary_max" DECIMAL(10,2),
    "employment_type" VARCHAR(50),
    "benefits" TEXT,

    CONSTRAINT "PositionSalary_pkey" PRIMARY KEY ("id")
);

-- Criar índices para PositionSalary
CREATE UNIQUE INDEX "PositionSalary_position_id_key" ON "PositionSalary"("position_id");
CREATE INDEX "PositionSalary_position_id_idx" ON "PositionSalary"("position_id");
CREATE INDEX "PositionSalary_employment_type_idx" ON "PositionSalary"("employment_type");
CREATE INDEX "PositionSalary_salary_min_salary_max_idx" ON "PositionSalary"("salary_min", "salary_max");

-- Criar tabela de endereços
CREATE TABLE "Address" (
    "id" SERIAL NOT NULL,
    "street" VARCHAR(100),
    "city" VARCHAR(100) NOT NULL,
    "state" VARCHAR(50),
    "postal_code" VARCHAR(20),
    "country" VARCHAR(50) NOT NULL,

    CONSTRAINT "Address_pkey" PRIMARY KEY ("id")
);

-- Criar índices para Address
CREATE INDEX "Address_city_idx" ON "Address"("city");
CREATE INDEX "Address_country_idx" ON "Address"("country");

-- Criar tabela de histórico de status de candidaturas
CREATE TABLE "ApplicationStatusHistory" (
    "id" SERIAL NOT NULL,
    "application_id" INTEGER NOT NULL,
    "old_status_id" INTEGER,
    "new_status_id" INTEGER NOT NULL,
    "change_date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "changed_by_id" INTEGER,
    "notes" TEXT,

    CONSTRAINT "ApplicationStatusHistory_pkey" PRIMARY KEY ("id")
);

-- Criar índices para ApplicationStatusHistory
CREATE INDEX "ApplicationStatusHistory_application_id_idx" ON "ApplicationStatusHistory"("application_id");
CREATE INDEX "ApplicationStatusHistory_change_date_idx" ON "ApplicationStatusHistory"("change_date");
CREATE INDEX "ApplicationStatusHistory_changed_by_id_idx" ON "ApplicationStatusHistory"("changed_by_id");

-- Criar tabela de histórico de resultados de entrevistas
CREATE TABLE "InterviewResultHistory" (
    "id" SERIAL NOT NULL,
    "interview_id" INTEGER NOT NULL,
    "old_result_id" INTEGER,
    "new_result_id" INTEGER NOT NULL,
    "change_date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "changed_by_id" INTEGER,
    "old_score" INTEGER,
    "new_score" INTEGER,
    "notes" TEXT,

    CONSTRAINT "InterviewResultHistory_pkey" PRIMARY KEY ("id")
);

-- Criar índices para InterviewResultHistory
CREATE INDEX "InterviewResultHistory_interview_id_idx" ON "InterviewResultHistory"("interview_id");
CREATE INDEX "InterviewResultHistory_change_date_idx" ON "InterviewResultHistory"("change_date");
CREATE INDEX "InterviewResultHistory_changed_by_id_idx" ON "InterviewResultHistory"("changed_by_id");

-- Adicionar campo de location_id à tabela Position
ALTER TABLE "Position" ADD COLUMN "location_id" INTEGER;
ALTER TABLE "Position" ADD COLUMN "status_id" INTEGER;

-- Criar valores iniciais na tabela StatusType
INSERT INTO "StatusType" ("name", "category") VALUES 
('Open', 'position'),
('Closed', 'position'),
('Draft', 'position'),
('New', 'application'),
('In Review', 'application'),
('Interviewing', 'application'),
('Rejected', 'application'),
('Accepted', 'application'),
('Pass', 'interview'),
('Fail', 'interview'),
('No Show', 'interview'),
('Reschedule', 'interview');

-- Inserir dados de localização padrão
INSERT INTO "CompanyLocation" ("company_id", "city", "country", "is_remote")
SELECT id, 'Default City', 'Default Country', false
FROM "Company";

-- Adicionar campo address_id à tabela Candidate
ALTER TABLE "Candidate" ADD COLUMN "address_id" INTEGER;

-- Migrar endereços existentes para a tabela Address
INSERT INTO "Address" ("city", "country")
SELECT 'Default City', 'Default Country';

-- Migrar dados para os novos campos
-- Atualizar location_id nas posições existentes
UPDATE "Position" SET "location_id" = (
    SELECT "id" FROM "CompanyLocation" WHERE "company_id" = "Position"."company_id" LIMIT 1
);

-- Atualizar status_id nas posições existentes
UPDATE "Position" SET "status_id" = (
    SELECT "id" FROM "StatusType" WHERE "name" = 'Open' AND "category" = 'position' LIMIT 1
);

-- Adicionar campo status_id à tabela Application
ALTER TABLE "Application" ADD COLUMN "status_id" INTEGER;

-- Atualizar status_id nas candidaturas existentes
UPDATE "Application" SET "status_id" = (
    SELECT "id" FROM "StatusType" WHERE "name" = 'New' AND "category" = 'application' LIMIT 1
);

-- Migrar dados das posições para as tabelas normalizadas
INSERT INTO "PositionDetails" (
    "position_id", "description", "job_description", "requirements", "responsibilities", 
    "company_description", "application_deadline", "contact_info"
)
SELECT 
    "id", "description", "job_description", "requirements", "responsibilities", 
    "company_description", "application_deadline", "contact_info"
FROM "Position";

INSERT INTO "PositionSalary" (
    "position_id", "salary_min", "salary_max", "employment_type", "benefits"
)
SELECT 
    "id", "salary_min", "salary_max", "employment_type", "benefits"
FROM "Position";

-- Adicionar campo result_id à tabela Interview
ALTER TABLE "Interview" ADD COLUMN "result_id" INTEGER;

-- Atualizar result_id nas entrevistas existentes
UPDATE "Interview" SET "result_id" = (
    SELECT "id" FROM "StatusType" 
    WHERE ("Interview"."result" = "name" OR ("Interview"."result" IS NULL AND "name" = 'Pass'))
    AND "category" = 'interview' 
    LIMIT 1
);

-- Tornar obrigatórios os campos que foram migrados
ALTER TABLE "Position" ALTER COLUMN "location_id" SET NOT NULL;
ALTER TABLE "Position" ALTER COLUMN "status_id" SET NOT NULL;
ALTER TABLE "Application" ALTER COLUMN "status_id" SET NOT NULL;

-- Adicionar chaves estrangeiras para as novas relações
ALTER TABLE "Position" ADD CONSTRAINT "Position_location_id_fkey" FOREIGN KEY ("location_id") REFERENCES "CompanyLocation"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Position" ADD CONSTRAINT "Position_status_id_fkey" FOREIGN KEY ("status_id") REFERENCES "StatusType"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "PositionDetails" ADD CONSTRAINT "PositionDetails_position_id_fkey" FOREIGN KEY ("position_id") REFERENCES "Position"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "PositionSalary" ADD CONSTRAINT "PositionSalary_position_id_fkey" FOREIGN KEY ("position_id") REFERENCES "Position"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Candidate" ADD CONSTRAINT "Candidate_address_id_fkey" FOREIGN KEY ("address_id") REFERENCES "Address"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "Application" ADD CONSTRAINT "Application_status_id_fkey" FOREIGN KEY ("status_id") REFERENCES "StatusType"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "Interview" ADD CONSTRAINT "Interview_result_id_fkey" FOREIGN KEY ("result_id") REFERENCES "StatusType"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "ApplicationStatusHistory" ADD CONSTRAINT "ApplicationStatusHistory_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "Application"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ApplicationStatusHistory" ADD CONSTRAINT "ApplicationStatusHistory_changed_by_id_fkey" FOREIGN KEY ("changed_by_id") REFERENCES "Employee"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "InterviewResultHistory" ADD CONSTRAINT "InterviewResultHistory_interview_id_fkey" FOREIGN KEY ("interview_id") REFERENCES "Interview"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "InterviewResultHistory" ADD CONSTRAINT "InterviewResultHistory_changed_by_id_fkey" FOREIGN KEY ("changed_by_id") REFERENCES "Employee"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Adicionar índices nas tabelas existentes
CREATE INDEX "Company_name_idx" ON "Company"("name");
CREATE INDEX "Employee_company_id_idx" ON "Employee"("company_id");
CREATE INDEX "Employee_email_idx" ON "Employee"("email");
CREATE INDEX "Employee_role_idx" ON "Employee"("role");
CREATE INDEX "Employee_is_active_idx" ON "Employee"("is_active");
CREATE INDEX "InterviewFlow_description_idx" ON "InterviewFlow"("description");
CREATE INDEX "InterviewType_name_idx" ON "InterviewType"("name");
CREATE INDEX "InterviewStep_interview_flow_id_idx" ON "InterviewStep"("interview_flow_id");
CREATE INDEX "InterviewStep_interview_type_id_idx" ON "InterviewStep"("interview_type_id");
CREATE INDEX "InterviewStep_order_index_idx" ON "InterviewStep"("order_index");
CREATE INDEX "Position_company_id_idx" ON "Position"("company_id");
CREATE INDEX "Position_interview_flow_id_idx" ON "Position"("interview_flow_id");
CREATE INDEX "Position_status_id_idx" ON "Position"("status_id");
CREATE INDEX "Position_is_visible_idx" ON "Position"("is_visible");
CREATE INDEX "Position_company_id_is_visible_idx" ON "Position"("company_id", "is_visible");
CREATE INDEX "Position_title_idx" ON "Position"("title");
CREATE INDEX "Candidate_firstName_lastName_idx" ON "Candidate"("firstName", "lastName");
CREATE INDEX "Candidate_email_idx" ON "Candidate"("email");
CREATE INDEX "Candidate_address_id_idx" ON "Candidate"("address_id");
CREATE INDEX "Education_candidateId_idx" ON "Education"("candidateId");
CREATE INDEX "Education_institution_idx" ON "Education"("institution");
CREATE INDEX "WorkExperience_candidateId_idx" ON "WorkExperience"("candidateId");
CREATE INDEX "WorkExperience_company_idx" ON "WorkExperience"("company");
CREATE INDEX "WorkExperience_position_idx" ON "WorkExperience"("position");
CREATE INDEX "Resume_candidateId_idx" ON "Resume"("candidateId");
CREATE INDEX "Resume_fileType_idx" ON "Resume"("fileType");
CREATE INDEX "Resume_uploadDate_idx" ON "Resume"("uploadDate");
CREATE INDEX "Application_position_id_idx" ON "Application"("position_id");
CREATE INDEX "Application_candidate_id_idx" ON "Application"("candidate_id");
CREATE INDEX "Application_status_id_idx" ON "Application"("status_id");
CREATE INDEX "Application_application_date_idx" ON "Application"("application_date");
CREATE INDEX "Application_position_id_status_id_idx" ON "Application"("position_id", "status_id");
CREATE INDEX "Interview_application_id_idx" ON "Interview"("application_id");
CREATE INDEX "Interview_interview_step_id_idx" ON "Interview"("interview_step_id");
CREATE INDEX "Interview_employee_id_idx" ON "Interview"("employee_id");
CREATE INDEX "Interview_interview_date_idx" ON "Interview"("interview_date");
CREATE INDEX "Interview_result_id_idx" ON "Interview"("result_id");
CREATE INDEX "Interview_application_id_result_id_idx" ON "Interview"("application_id", "result_id");

-- Remover colunas que foram migradas para outras tabelas
ALTER TABLE "Position" DROP COLUMN "description";
ALTER TABLE "Position" DROP COLUMN "location";
ALTER TABLE "Position" DROP COLUMN "job_description";
ALTER TABLE "Position" DROP COLUMN "requirements";
ALTER TABLE "Position" DROP COLUMN "responsibilities";
ALTER TABLE "Position" DROP COLUMN "salary_min";
ALTER TABLE "Position" DROP COLUMN "salary_max";
ALTER TABLE "Position" DROP COLUMN "employment_type";
ALTER TABLE "Position" DROP COLUMN "benefits";
ALTER TABLE "Position" DROP COLUMN "company_description";
ALTER TABLE "Position" DROP COLUMN "application_deadline";
ALTER TABLE "Position" DROP COLUMN "contact_info";
ALTER TABLE "Position" DROP COLUMN "status";
ALTER TABLE "Application" DROP COLUMN "status";
ALTER TABLE "Interview" DROP COLUMN "result";
ALTER TABLE "Candidate" DROP COLUMN "address"; 