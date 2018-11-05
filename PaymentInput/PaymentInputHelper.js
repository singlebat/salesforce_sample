({
 	track: function(component){
        var action = component.get("c.trackTool"); 
        action.setParams({
            toolName: 'IMRR_DisplayWithEdit',
        });
        action.setCallback(this, function(a) {
            console.log('tool: ' + a.getReturnValue());
        });
        $A.enqueueAction(action);         
    },
    dropEvent: function(event){

        event.stopPropagation();
        event.preventDefault();
        event.dataTransfer.dropEffect = 'copy';        
    },
    loadFiles: function(component){
    	var helper = this;
    	//helper.toggleSpinner(component,true);
        var action = component.get("c.getAllFilesList");
        var recordId = component.get("v.recordId");
        action.setParams({
            recordId: recordId
        });
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
               
            }
            //helper.toggleSpinner(component,false);
            component.set("v.isEdit", false);
        });
        $A.enqueueAction(action);
    },
    createFileObj: function(record){
        var base64Data = null;
        if(record.imageUrl && record.imageUrl.indexOf('base64') > -1){
            base64Data = record.imageUrl.match(/,(.*)$/)[1];            
        }

        if(!record.isDeleted){
            record.base64Data = base64Data;
        }
        //alert('this is'+base64Data);
        return record;
    },
    doSave: function(files, component, helper, callback){
        if(files==null || files.length==0){
            callback();
            return;
        }
        //alert('4');
        var min = 990000, paramString = '', index = 0, len=files.length, newString='';
        var fileObjArray = [], remainingFilesArray = [];
        do{
            //alert('5');
            newString = JSON.stringify(files[index]);
             alert(newString);
            if(paramString.length+newString.length+1>min){
                remainingFilesArray = files.slice(index);
                break;
            }else{
                fileObjArray.push(files[index]);
                paramString = JSON.stringify(fileObjArray);
            }
            index++;
        }while(index<len);
        

        var action = component.get("c.saveBatchFiles");
        action.setParams({
            files: paramString,
        });
        action.setCallback(this, function(a) {
            helper.doSave(remainingFilesArray, component, helper, callback);
        });
        $A.enqueueAction(action);
    },    
    saveByChunk: function(file, start, fileArray, component, helper, callback){
        var min=800000, nextStart=0;
        var base64Data = file.base64Data.substring(start);
        if(base64Data.length>min){
            base64Data = base64Data.substring(0, min);
            nextStart = start+min;
        }
        //alert('10');
        var action = component.get("c.saveIndividualFile");
        var paramFile = {
            id: file.id,
            name: file.name,
            parentId: file.parentId,
            isAttachment: file.isAttachment,
            base64Data: null,
        };
        if(file.isAttachment){
            paramFile.contentType = file.contentType;
        }else{
            paramFile.contentDocumentId = file.contentDocumentId;            
        }
        action.setParams({
            fileString: JSON.stringify(paramFile),
            base64Data: base64Data,
            isStart: start==0 ? true : false,
        });
        action.setCallback(this, function(a) {
            if(nextStart!=0){   //send same file
                file.id = a.getReturnValue();

                console.log('Id'+file.Id);
                console.log('go to next chunk: ', nextStart);
                helper.saveByChunk(file, nextStart, fileArray, component, helper, callback);
            }else{  //send next file


                console.log('go to next file: ');
                if(fileArray && fileArray.length>0){
                    helper.saveByChunk(fileArray[0], nextStart, fileArray.slice(1), component, helper, callback);
                }else{
                    console.log('end');
                    callback();
                    return ;
                }
            }            
        });
        $A.enqueueAction(action);
    },
    saveFiles: function(component, helper,files,loadAllCallback){
        if(files==null || files.length==0){
            return;
        }
        
        var fileSmallObjArray = [], fileBigObjArray = [], min = 990000;
        for(var i=0, len=files.length; i<len; i++){
            var record = files[i];
            //alert('this is a record:'+record);
            if(JSON.stringify(record).length>min){
                fileBigObjArray.push(record);
            }else{
                fileSmallObjArray.push(record);
            }                
        }
        var saveBigObjArray = function(){
            if(fileBigObjArray && fileBigObjArray.length>0){
                helper.saveByChunk(fileBigObjArray[0], 0, fileBigObjArray.slice(1), component, helper, loadAllCallback);
            }else{
                loadAllCallback();
            }
        };
        if(fileSmallObjArray && fileSmallObjArray.length>0){
            helper.doSave(fileSmallObjArray, component, helper, saveBigObjArray);            
        }else if(fileBigObjArray && fileBigObjArray.length>0){
            saveBigObjArray();
        }else{

        }
    },
    setNewFile: function(files, newFile, parentId, callback){
        var reg=/(.*)(?:\.([^.]+$))/;
        var fileName = newFile.name;
        var name = fileName.match(reg)[1];
        var type = fileName.match(reg)[2];
        var pricerType,pricerMasterType,groupName,oppId,accId,bunName;
        var arrName = name.split("_");
        if (arrName.length == 5){
            bunName = arrName[1] + "_" + arrName[2] + "_" +arrName[3] + "_" +arrName[4];
            if (arrName[3].length != 18){
                pricerType = arrName[0];
                pricerMasterType = arrName[1];
                groupName = arrName[3];                
                oppId = arrName[4];
            } else {
                pricerType = arrName[0];
                pricerMasterType = arrName[1];
                oppId = arrName[3];
                accId = arrName[4];
            }
        } else if (arrName.length == 6){ 
            bunName = arrName[1] + "_" + arrName[2] + "_" +arrName[3] + "_" +arrName[4] + "_" +arrName[5];
            pricerType = arrName[0];
            pricerMasterType = arrName[1];
            groupName = arrName[2];                   
            oppId = arrName[4];
            accId = arrName[5];
        }


        //ファイル設定を処理する必要
        callback(newFile);
    },
    readFile: function(file, callback) {
        if (!file) return;
        var reader = new FileReader();
        reader.readAsText(file,'Shift_JIS');
        reader.onloadend = function() {
            var fileData = {
                name: file.name,
            	content: reader.result,
                isShowIcon: file.type.indexOf('image')>-1 ? false : true,
                size: file.size,
            };
            callback(fileData);
            console.log(reader.result);
        };
        //alert(reader.result);
        //reader.readAsDataURL(file);  
    },

    compare:function (prop) {
        return function (obj1, obj2) {
            var val1 = obj1[prop];
            var val2 = obj2[prop];
            if (!isNaN(Number(val1)) && !isNaN(Number(val2))) {
                val1 = Number(val1);
                val2 = Number(val2);
            }
            if (val1 < val2) {
                return -1;
            } else if (val1 > val2) {
                return 1;
            } else {
                return 0;
            }            
        } 
    },
    resetProgross :function(component){
        component.set("v.csvNum",1);
        component.set("v.excNum",1);
        component.set("v.maxFileSize",null);
        component.set("v.csvProgress",0);
        component.set("v.excProgress",0);
    },
    setProgross : function(component,type){
        if(type == 'csv'){
            var num = component.get("v.csvNum")+1;
            var progress = num / component.get("v.maxFileSize") * 100;
            component.set("v.csvNum",num);
            component.set("v.csvProgress",progress);
        }else{
            var num = component.get("v.excNum")+1;
            var progress = num / component.get("v.maxFileSize") * 100;
            component.set("v.excNum",num);
            component.set("v.excProgress",progress);
        }

    },
    //csv IDにより　　見積リストを作る
    createQuoteRecords:function(component,csvFileList,toSaveExcFileCallback){
        var helper = this;
        var action = component.get("c.createQuoteRecordList");

        var noBodyCsvFileList = [];
        for(var csv of csvFileList){
            var newCsv = helper.cloneObj(csv);
            newCsv.base64Data = null;
            newCsv.imageUrl = null;
            noBodyCsvFileList.push(newCsv);
        }
        console.log(JSON.stringify(noBodyCsvFileList));

        action.setParams({
            "csvfileJson":JSON.stringify(noBodyCsvFileList)
        });
        action.setCallback(this,function(res){
            if(component.isValid() && res.getState() === "SUCCESS"){
                helper.removeError(component);
                toSaveExcFileCallback(res.getReturnValue());
            }else{
                helper.showError(component,res.getError(),true);
                //エラーが発生する場合，falseを返す
                toSaveExcFileCallback(false);
            }
        })
        $A.enqueueAction(action);
    },
    getErrorMsg : function(component){
        var helper = this;
        var action = component.get("c.getErrorsByOppId");
        action.setParams({
            "OpportunityId":component.get("v.recordId")
        });
        action.setCallback(this,function(res){
            if(component.isValid() && res.getState() === "SUCCESS"){
                component.set("v.errList",res.getReturnValue());
            }else{
                helper.showError(component,res.getError(),true);
            }
        })
        $A.enqueueAction(action);
    },
    setIsDeleted: function(id, files, isDeleted, callback){
        
    },
    resetErrorMsg : function(component){
        component.set("v.errList",[]);
        var helper = this;
        var action = component.get("c.resetErrorsByOppId");
        action.setParams({
            "OpportunityId":component.get("v.recordId")
        });
        action.setCallback(this,function(res){
            if(component.isValid() && res.getState() === "SUCCESS"){
                
            }else{
                helper.showError(component,res.getError(),true);
            }
        })
        $A.enqueueAction(action);
    }
})