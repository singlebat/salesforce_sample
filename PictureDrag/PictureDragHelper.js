({
    readFile: function(component, helper, file) {
        if (!file) return;
        if (!file.type.match(/(image.*)/)) {
            return alert('Image file not supported');
        }

        //画像のサイズ
        var imgSize = file.size;
        console.log('size:'+imgSize);
        if (imgSize < 100 * 1024) {    //1000kb
            //コンプレス必要がない
            var reader = new FileReader();
            reader.onloadend = function() {
                var dataURL = reader.result;
                component.set("v.pictureSrc", dataURL);
                helper.upload(component, file, dataURL.match(/,(.*)$/)[1]);
            };
            reader.readAsDataURL(file);
        } else {
            //コンプレス
            var reader = new FileReader();

            reader.onloadend = function(e) {
                var base64Img = e.target.result;   // = dataURL
                // component.set("v.pictureSrc", base64Img);
                // var base64Img = reader.result;
                //--执行resize。
                
                helper.compress({
                    ratio: 0.7 //压缩率
                    ,
                    dataSource: base64Img//数据源。数据源是指需要压缩的数据源，有三种类型，image图片元素，base64字符串，canvas对象，还有选择文件时候的file对象。。。  
                    ,
                    dataSourceType: "base64" //image  base64 canvas
                    ,
                    maxWidth: 800 //允许的最大宽度
                    ,
                    maxHeight: 800 //允许的最大高度。
                },function(dataURL){
                    //成功したら
                    component.set("v.pictureSrc",dataURL);
                    helper.upload(component, file, dataURL.match(/,(.*)$/)[1]);
                });
                    
            };
            reader.readAsDataURL(file);
        }
    },

    upload: function(component, file, base64Data) {
        var action = component.get("c.saveAttachment");
        console.log('SobjectName:' + component.get("v.sObjectName"));
        action.setParams({
            parentId: component.get("v.recordId"),
            fileName: file.name,
            base64Data: base64Data,
            contentType: file.type,
            sobjectName:component.get("v.sObjectName")
        });
        action.setCallback(this, function(res) {
            if (component.isValid() && res.getState() === "SUCCESS") {
                component.set("v.message", "アップロード成功しました");
            } else {
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "エラー!",
                    "message": "アップロード失敗でした",
                    "type": "error"
                });
                toastEvent.fire();
            }
        });
        component.set("v.message", "コンプレス中...");
        $A.enqueueAction(action);
    },


    /**
     * 这是基于html5的前端图片工具，压缩工具。
     */
    compress:function(opts,success) {
        var canvas = document.createElement('canvas');
        canvas.width = opts.maxWidth;
        canvas.height = opts.maxHeight;


        //元のImg
        var img = new Image();
        img.src = opts.dataSource;

        img.onload = function(){
            var ctx = canvas.getContext("2d");
            ctx.drawImage(img, 0, 0, opts.maxWidth, opts.maxHeight);
            var img64 = canvas.toDataURL("image/jpeg",opts.ratio); //新しいのImg

            success(img64);
        };
    },

    dataURLtoBlob: function(dataurl) {
        var arr = dataurl.split(','),
            mime = arr[0].match(/:(.*?);/)[1],
            bstr = atob(arr[1]),
            n = bstr.length,
            u8arr = new Uint8Array(n);
        while (n--) {
            u8arr[n] = bstr.charCodeAt(n);
        }
        return new Blob([u8arr], { type: mime });
    }
})