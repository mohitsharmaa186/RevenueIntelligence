/**
 * @description Trigger handler framework — routes trigger events to handler methods.
 */
public virtual class TriggerHandler {
    private static Map<String, LoopCount> loopCountMap = new Map<String, LoopCount>();
    private static Set<String> bypassedHandlers = new Set<String>();

    public enum TriggerContext {
        BEFORE_INSERT, BEFORE_UPDATE, BEFORE_DELETE,
        AFTER_INSERT, AFTER_UPDATE, AFTER_DELETE, AFTER_UNDELETE
    }

    public TriggerHandler() {}

    public void run() {
        if (!validateRun()) {
            return;
        }
        addToLoopCount();

        if (Trigger.isExecuting) {
            if (Trigger.isBefore && Trigger.isInsert) {
                this.beforeInsert();
            } else if (Trigger.isBefore && Trigger.isUpdate) {
                this.beforeUpdate();
            } else if (Trigger.isBefore && Trigger.isDelete) {
                this.beforeDelete();
            } else if (Trigger.isAfter && Trigger.isInsert) {
                this.afterInsert();
            } else if (Trigger.isAfter && Trigger.isUpdate) {
                this.afterUpdate();
            } else if (Trigger.isAfter && Trigger.isDelete) {
                this.afterDelete();
            } else if (Trigger.isAfter && Trigger.isUndelete) {
                this.afterUndelete();
            }
        }
    }

    public static void bypass(String handlerName) {
        bypassedHandlers.add(handlerName);
    }

    public static void clearBypass(String handlerName) {
        bypassedHandlers.remove(handlerName);
    }

    public static Boolean isBypassed(String handlerName) {
        return bypassedHandlers.contains(handlerName);
    }

    public static void clearAllBypasses() {
        bypassedHandlers.clear();
    }

    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

    private Boolean validateRun() {
        if (!Trigger.isExecuting) {
            return true;
        }
        String handlerName = String.valueOf(this).substringBefore(':');
        if (bypassedHandlers.contains(handlerName)) {
            return false;
        }
        LoopCount lc = loopCountMap.get(handlerName);
        if (lc == null) {
            lc = new LoopCount();
            loopCountMap.put(handlerName, lc);
        }
        return lc.increment();
    }

    private void addToLoopCount() {
        String handlerName = String.valueOf(this).substringBefore(':');
        LoopCount lc = loopCountMap.get(handlerName);
        if (lc == null) {
            lc = new LoopCount();
            loopCountMap.put(handlerName, lc);
        }
    }

    private class LoopCount {
        private Integer max = 5;
        private Integer count = 0;

        public Boolean increment() {
            count++;
            return count <= max;
        }
    }
}
