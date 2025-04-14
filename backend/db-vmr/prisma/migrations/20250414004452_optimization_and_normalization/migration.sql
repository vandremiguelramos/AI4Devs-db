/*
  Warnings:

  - A unique constraint covering the columns `[name]` on the table `InterviewType` will be added. If there are existing duplicate values, this will fail.

*/
-- DropForeignKey
ALTER TABLE "ApplicationStatusHistory" DROP CONSTRAINT "ApplicationStatusHistory_application_id_fkey";

-- DropForeignKey
ALTER TABLE "InterviewResultHistory" DROP CONSTRAINT "InterviewResultHistory_interview_id_fkey";

-- DropForeignKey
ALTER TABLE "PositionDetails" DROP CONSTRAINT "PositionDetails_position_id_fkey";

-- DropForeignKey
ALTER TABLE "PositionSalary" DROP CONSTRAINT "PositionSalary_position_id_fkey";

-- CreateIndex
CREATE UNIQUE INDEX "InterviewType_name_key" ON "InterviewType"("name");

-- CreateIndex
CREATE INDEX "Position_location_id_idx" ON "Position"("location_id");

-- AddForeignKey
ALTER TABLE "PositionDetails" ADD CONSTRAINT "PositionDetails_position_id_fkey" FOREIGN KEY ("position_id") REFERENCES "Position"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PositionSalary" ADD CONSTRAINT "PositionSalary_position_id_fkey" FOREIGN KEY ("position_id") REFERENCES "Position"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ApplicationStatusHistory" ADD CONSTRAINT "ApplicationStatusHistory_application_id_fkey" FOREIGN KEY ("application_id") REFERENCES "Application"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "InterviewResultHistory" ADD CONSTRAINT "InterviewResultHistory_interview_id_fkey" FOREIGN KEY ("interview_id") REFERENCES "Interview"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
