({  
     doInit: function(component, event, helper) {
        helper.loadFiles(component);
        //helper.track(component);
    },
    openContent : function(component, event, helper) {
        var idx = event.target.getAttribute("data-contentdocumentid");
        $A.get('e.forceContent:openPreview').setParams({ recordId: idx }).fire();
    },
    editMode : function(component, event, helper){
        component.set("v.isEdit", true);
    },
    reload: function(component, event, helper){
        helper.loadFiles(component);
        component.set("v.isEdit", false);
    }, 
    saveFiles: function(component, event, helper){
        //ファイル 整理
        var fileSetList = component.get("v.fileSetList");
        var csvFileList = [];
        for(var fileSet of fileSetList){
            if(fileSet.csvFile == null){
                //ファイルを揃えてない場合,Error になる
                fileSet.error = 'ファイルが足りません';
            }else{
                fileSet.error = null;
                csvFileList.push(fileSet.csvFile);
                //alert(csvFileList);
            }
        }
        component.set("v.fileSetList",fileSetList);
        if(csvFileList.length == 0){
            return;
        }
        //1.CSV ファイルアップロードのCallbak
        var csvloadAllCallback = function(){
            //2.成功したら、見積レコードをインサート作業を始まり
            helper.resetErrorMsg(component);
        }

        //helper.toggleSpinner(component,true);
        // component.set("v.isLoading",true);
        helper.resetProgross(component);

        //1.CSV ファイル先にアップロード
        helper.saveFiles(component, helper,csvFileList,csvloadAllCallback);
        
        //alert('保存完了');
        //保存成功のファイルを全部削除
        component.set("v.fileSetList", []);  
    },
    deleteFile: function(component, event, helper){
        var callback = function(files){

        };
        //server のファイルを削除する
        if(!$A.util.isUndefinedOrNull(event.target.id)){
            helper.setIsDeleted(event.target.id, component.get("v.files"), true, callback);
        }

        var fileSetList = component.get("v.fileSetList");
        var index = event.target.name;
        var fileType = event.target.title;

        var fileset = fileSetList[index];
        if(fileType == 'csv'){
            fileset.csvFile = null;
        }
        
        if(fileset.csvFile == null){
            fileSetList.splice(index,1);
        }

        component.set("v.fileSetList",fileSetList);
    },
    undoDeleteFile: function(component, event, helper){
        var callback = function(files){
            component.set("v.files", files);
        };
        helper.setIsDeleted(event.target.id, component.get("v.files"), false, callback);        
    },
    onDragOver: function(component, event) {
        event.preventDefault();
    },
    onDropUpdate: function(component, event, helper) {
        console.log("onDropUpdate");
        helper.dropEvent(event);
        var setFilesCallback = function(newComponentFiles){
            component.set("v.files", newComponentFiles);            
        }
        var readFileCallback = function(readFile){
            var id = event.target.id;
            var componentFiles = component.get("v.files");
            helper.setFile(id, componentFiles, readFile, setFilesCallback);
        };
        var files = event.dataTransfer.files;
        if(files && files.length>0){
            helper.readFile(files[0], readFileCallback);
        }  
    },

     //新しいファイルを引っ張られた
    onDropNew: function(component, event, helper){
        console.log("onDropNew");
        helper.dropEvent(event);
        var setFilesCallback = function(newComponentFile){
            //newComponentFile  :新しい一つのファイル
            var fileSetList = component.get("v.fileSetList");
			//alert(fileSetList);
            //存在するがどうかのフラグ
            var existFlag = false;
            if(fileSetList!=null){
                for(var fileSet of fileSetList){
                    //1.全てのファイルの中に同じ名前のファイルを見つかります
                    if(fileSet.name == newComponentFile.name){
                        fileSet.csvFile = newComponentFile;
                        existFlag = true;   //存在を見つけた
                        break;
                    }             
                }
			}
            //3.なかったら 新規ファイル居場所を作る
            if(!existFlag){
                var fileSet = {
                    name:null,
                    csvFile:null,
                }
                fileSet.name = newComponentFile.name;
                fileSet.csvFile = newComponentFile;
                fileSetList.push(fileSet);
            }
            component.set("v.fileSetList",fileSetList);            
        }

        var fileSize = 0;
        var readFileCallback = function(readFile){
            fileSize --;
            if(fileSize == 0){
               // helper.toggleSpinner(component,false);
            }
            //読み込み成功のファイル
            helper.setNewFile(null, readFile, component.get("v.recordId"), setFilesCallback,component);
        };

        var files = event.dataTransfer.files;
        fileSize = files.length;
        if(files && files.length>0){
            //helper.toggleSpinner(component,true);
            for(var i=0, len=files.length; i<len; i++){
                helper.readFile(files[i], readFileCallback); 
            }
        }
        
    },
    handleUploadFinished : function(component, event, helper) {
  		var fileInput = component.find("file").getElement(); 
        helper.upload(component, helper, fileInput);
    },
})