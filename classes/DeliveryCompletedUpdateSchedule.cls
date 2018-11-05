global class DeliveryCompletedUpdateSchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        DeliveryCompletedUpdateBatch batch = new DeliveryCompletedUpdateBatch();
        Database.executeBatch(batch, 200);
    }
}