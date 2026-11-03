trigger OrderTrigger on Order__c(before insert, before update, after update) {
  if (Trigger.isBefore) {
    if (Trigger.isInsert) {
      OrderTriggerHandler.beforeInsert(Trigger.new);
    } else if (Trigger.isUpdate) {
      OrderTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    }
  } else if (Trigger.isAfter) {
    if (Trigger.isUpdate) {
      OrderTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}
