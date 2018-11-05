public with sharing class Crud {
    /*
    ----------------------------------------------------------------------
    -- - Author        : Spoon Consulting
    -- - Description   : Manage CRUD in VisualForce page and Lightning Components
    -- -             
    -- - Maintenance History:
    --
    -- Date         Name  Version  Remarks 
    -- -----------  ----  -------  ---------------------------------------
    -- 04-NOV-2016  DMT   1.0      Initial version 
    ----------------------------------------------------------------------
    */
    private static Integer ISUPDATEABLE = 1;
    private static Integer ISDELETABLE = 2;
    private static Integer ISCREATEABLE = 3;
    private static Integer ISACCESSIBLE = 4;

    public static boolean isCreateable(Schema.SObjectType sobjType) {
        return ObjectPermission(sobjType, ISCREATEABLE);
    }
    
    public static boolean isUpdateable(Schema.SObjectType sobjType) {
        return ObjectPermission(sobjType, ISUPDATEABLE);
    }
    
    public static boolean isDeletable(Schema.SObjectType sobjType) {
        return ObjectPermission(sobjType, ISDELETABLE);
    }
    
    public static boolean isAccessible(Schema.SObjectType sobjType) {
        return ObjectPermission(sobjType, ISACCESSIBLE);
    }

    public static boolean ObjectPermission(Schema.SObjectType sobjType, Integer permissionType) {
        if ((permissionType == ISCREATEABLE && sobjType.getDescribe().isCreateable()) ||
            (permissionType == ISUPDATEABLE && sobjType.getDescribe().isUpdateable()) ||
            (permissionType == ISACCESSIBLE && sobjType.getDescribe().isAccessible())) {
            return true;
        } else if (permissionType == ISDELETABLE) {
            return sobjType.getDescribe().isDeletable();
        } else {
            return false;
        }
    }
}