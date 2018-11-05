({  
    // Load current profile picture
    onInit: function(component) {
        var action = component.get("c.getProfilePicture"); 
        action.setParams({
            parentId: component.get("v.recordId"),
        });
        action.setCallback(this, function(a) {
            var files = a.getReturnValue();
            if (files && files.length > 0) {
                component.set('v.pictureSrc', '/sfc/servlet.shepherd/version/download/' 
                                                  + files[0].Id);
            }
        });
        $A.enqueueAction(action); 
    },
    
    onDragOver: function(component, event) {
        event.preventDefault();
    },

    onDrop: function(component, event, helper) {
        event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect = 'copy';
        var files = event.dataTransfer.files;
        if (files.length>1) {
            return alert("ファイルを一つしかアップロードできない");
        }
        helper.readFile(component, helper, files[0]);
    },

    save : function(component, event, helper) {
        var fileInput = component.find("file").getElement();
        var file = fileInput.files[0];

        helper.readFile(component, helper,file);
    },
    
})