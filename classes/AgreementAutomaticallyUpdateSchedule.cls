global with sharing class AgreementAutomaticallyUpdateSchedule implements Schedulable{
    global void execute(SchedulableContext ctx) {
        AgreementAutomaticallyUpdateBatch batch = new AgreementAutomaticallyUpdateBatch();
        Database.executeBatch(batch, 200);
    }
}