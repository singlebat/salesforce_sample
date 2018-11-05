({
	doInit : function(component, event, helper) {
        //レコードタイプ取得
        var action = component.get("c.getRecordTypeId");
        action.setCallback(this,function(res){
            if(component.isValid() && res.getState() === "SUCCESS"){
                var result = res.getReturnValue();
                for (var i = 0 ; i < result.length ; i++) {
                    if(result[i].Name == "リース"){
                        component.set("v.leaseRTId",result[i].Id);
                    }else if(result[i].Name == "販売"){
                        component.set("v.sellingRTId",result[i].Id);
                    }
                }
            }else{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "エラー!",
                    "message": "管理者にご連絡ください．",
                    "type":"error"
                });
                toastEvent.fire();
            }
        })
        $A.enqueueAction(action);

        if(typeof dragManager != 'undefined'){
            dragManager = null;
        }

        // window.reload();
        // location.reload();
        /*table tr 可拖动js整理*/
        console.log("load moveTr");
        //绑定事件
        var addEvent = document.addEventListener ? function(el,type,callback){
            el.addEventListener( type, callback, !1 );
            // console.log(el);
        } : function(el,type,callback){
            // console.log(22222);
            el.attachEvent( "on" + type, callback );

        }
        //移除事件
        var removeEvent = document.removeEventListener ? function(el,type,callback){
            el.removeEventListener( type, callback );
        } : function(el,type,callback){
            el.detachEvent( "on" + type, callback);
        }
        //精确获取样式
        var getStyle = document.defaultView ? function(el,style){
            return document.defaultView.getComputedStyle(el, null).getPropertyValue(style)
        } : function(el,style){
            style = style.replace(/\-(\w)/g, function($, $1){
                return $1.toUpperCase();
            });
            return el.currentStyle[style];
        }
        var dragManager = {
            globalId:null,
            clientY:0,
            draging:function(e){//mousemove时拖动行
                // console.log('draging');
                var dragObj = dragManager.dragObj;
                if(dragObj){
                    e = e || event;
                    if(window.getSelection){//w3c
                        window.getSelection().removeAllRanges();   //選択された内容をクリアする
                    //}else  if(document.selection){
                    //    document.selection.empty();//IE
                    }
                    var y = e.clientY;
                    var down = y > dragManager.clientY;//是否向下移动   
                    var tr = document.elementFromPoint(e.clientX,e.clientY);
                    // console.log(tr.nodeName);
                    if(tr){
                        tr = dragManager.getTrEvent(tr);
                        if(tr == null){
                            return;
                        }
                        if(tr.parentNode.getAttribute("id") == undefined  ||  tr.parentNode.getAttribute("id") == null
                         || tr.parentNode.getAttribute("id") != ('tableTrMove') + dragManager.globalId ){
                            return;
                        }
                        dragManager.clientY = y;
                        if( dragObj !== tr){
                            tr.parentNode.insertBefore(dragObj, (down ? tr.nextSibling : tr));    
                        }
                    };
                }
            },
            dragStart:function(e){
                console.log('dragStart');
                e = e || event;
                var target = e.target || e.srcElement;
                target = dragManager.getTrEvent(target);
                if(target == null){
                    return;
                } 
                //if (target.title == "locationName") {
                //    return;
                //}
                console.log(target);
                dragManager.dragObj = target;  //元々のDOM
                if(!target.getAttribute("data-background")){
                    var background = getStyle(target,"background-color");
                    //target.setAttribute("data-background",background)
                }
                //显示为可移动的状态
                //target.style.backgroundColor = "#87cefa";
                target.style.height = '44px';
                target.style.cursor = "move";
                // $(target).css('cursor','move');
                dragManager.clientY = e.clientY;
                addEvent(document,"mousemove",dragManager.draging);
                addEvent(document,"mouseup",dragManager.dragEnd);
            },
            dragEnd:function(e){
                console.log('dragEnd');
                var dragObj = dragManager.dragObj;  
                if (dragObj) {
                    e = e || event;
                    var target = e.target || e.srcElement;
                    target = dragManager.getTrEvent(target);
                    // if(target == null){
                    //     return;
                    // }
                    //dragObj.style.backgroundColor = dragObj.getAttribute("data-background");
                    // target.style.height = null;
                    dragObj.style.cursor = "default";
                    dragManager.dragObj = null;
                    removeEvent(document,"mousemove",dragManager.draging);
                    removeEvent(document,"mouseup",dragManager.dragEnd);
                    // helper.reSort(component);
                }
            },
            main:function(el){
                addEvent(el,"mousedown",dragManager.dragStart);
            },
            getTrEvent:function(target){
                //递归调用 TR Event
                if(target == undefined || target.nodeName == undefined){
                    return null;
                }
                if(target.nodeName == 'A' || target.nodeName == 'INPUT'){
                    return null;
                }
                if(target.nodeName == 'TR'){
                    return target;
                }else{
                    target = target.parentNode;
                    return this.getTrEvent(target);
                }
            }
        }

        var jqueryWait = {
            wait :function(){
                if(typeof jQuery !='undefined'){
                    console.log('jquery load success');
                    helper.getWonProductByMitumoriId(component);
                    var el = document.getElementById('tableTrMove'+component.getGlobalId());
                    if(el == null || el == undefined){
                        setTimeout(function(){
                            var el = document.getElementById('tableTrMove'+component.getGlobalId());
                            dragManager.globalId = component.getGlobalId();
                            dragManager.main(el); 
                        },1000)
                    }else{
                        var el = document.getElementById('tableTrMove'+component.getGlobalId());
                        dragManager.globalId = component.getGlobalId();
                        dragManager.main(el); 
                    }
                    console.log($(".resizableTable"));
                }else{
                    console.log('jquery load error');
                    setTimeout(function(){
                        jqueryWait.wait();
                    },500);
                }        
            }
        }
        jqueryWait.wait();
	},
	
	/** 
     * 商品一覧リフレッシュ処理
     */
    refresh:function(component,event,helper){
        console.log("refresh load success");
        helper.getWonProductByMitumoriId(component);
    },
    
    changesection:function(component, event, helper){
        var show = !component.get("v.section_show");
        component.set("v.section_show",show);
    },
    
    scriptsLoaded : function(component, event, helper){
        // console.log("jquery load success");
    },
    
    sortByField:function(component,event,helper){
        var target = event.srcElement;
        if(target == undefined || target == null){
            return;
        }
        if(target.nodeName != 'A'){
            target = target.parentNode;
        }
        var sortField = target.title;
        component.set("v.sortField",sortField);
        helper.getWonProductByMitumoriId(component);
    },
    
    /** 
     * ソートボタンを押して、新しいソート順より商品一覧を保存する。
     */
    save:function(component,event,helper){
        var toastEvent = $A.get("e.force:showToast");
        var ProductList = helper.reSort(component);
        
        var action = component.get("c.updateWonProduct");
        console.log("mySpinner start");
        $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
        action.setParams({"updateProductList":ProductList});
        action.setCallback(this,function(res){
            console.log("mySpinner end");
            $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            if(component.isValid() && res.getState() === "SUCCESS"){
                
                toastEvent.setParams({
                    "title": "更新成功",
                    "message": "更新成功しました",
                    "type":"success"
                });
                toastEvent.fire();
                $A.get('e.force:refreshView').fire();
            }else{
                toastEvent.setParams({
                    "title": "エラー!",
                    "message": "管理者にご連絡ください．",
                    "type":"error"
                });
                toastEvent.fire();
            }
        })
        $A.enqueueAction(action);
    },
    
    /** 
     * 編集アイコンを押して、新規・編集商品コンポーネントにパラメータを設定して、開きます。
     */
    editRecord:function(component,event,helper){
        console.log(event.currentTarget);

        var rowIndex = event.currentTarget.parentElement.rowIndex;
        var childNodes = event.currentTarget.parentElement.parentElement.childNodes;
        console.log(childNodes);
        for (var i = 0 ; i < childNodes.length ; i++) {
            console.log(childNodes[i].style.backgroundColor);
            childNodes[i].style.backgroundColor = "";
            if (i == rowIndex-1) {
                childNodes[i].style.backgroundColor = "#87cefa";
            }
        }

        var LocationProductList = component.get("v.oppProductList");
        console.log(LocationProductList[rowIndex-1].selectedFlg);
        component.set("v.newEditDivision","edit");
        component.set("v.productType",event.currentTarget.title);
        component.set("v.productId",event.currentTarget.id);
        console.log(LocationProductList[rowIndex-1].selectedFlg);

    },
    
    /** 
     * 削除アイコンを押して、商品を削除する。セット商品の場合、セット商品として全部消します。
     */
    removeRecord:function(component,event,helper){
        if(confirm("削除確認?")){
            var Id = event.getSource().get("v.name");
            var action = component.get("c.deletedRecordById");
            console.log("mySpinner start");
            $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
            action.setParams({"Id":Id});
            action.setCallback(this,function(res){
                console.log("mySpinner end");
                $A.util.toggleClass(component.find("mySpinner"),"slds-hide");
                if(component.isValid() && res.getState() === "SUCCESS"){
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "削除成功",
                        "message": "削除成功しました",
                        "type":"success"
                    });
                    toastEvent.fire();
                    $A.get('e.force:refreshView').fire();
                }else{
                    var toastEvent = $A.get("e.force:showToast");
                    toastEvent.setParams({
                        "title": "エラー!",
                        "message": "管理者にご連絡ください．",
                        "type":"error"
                    });
                    toastEvent.fire();
                }
            })
            $A.enqueueAction(action);
        }
    },
    
    /** 
     * 配送依頼
     */
    deliveryApply:function(component,event,helper){
        var ProductList = new Array();
        var LocationProductList = component.get("v.oppProductList");
        for (var j = 0 ; j < LocationProductList.length ; j++) {
        	if (LocationProductList[j].selectedFlg == true) {
        		ProductList.push(LocationProductList[j].oppProduct);
        	}
        }
        
        if (ProductList.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
        	toastEvent.setParams({
        		"title": "配送失敗",
        		"message": "商品を選択してください。",
        		"type":"warning"
        	});
        	toastEvent.fire();
        	return null;
        }
        
        component.set("v.ProductList",ProductList);
        component.set("v.showModal",true);
    },
    
    /** 
     * 商品全選択/解除
     */
    checkAll:function(component,event,helper){
        var flg  = component.get("v.checkFlag");
        var oppProductList   = component.get("v.oppProductList");
        for (var j = 0 ; j < oppProductList.length ; j++) {
	        if(oppProductList[j].oppProduct.Delivery__r.DeliveryStatus__c!='D/L（搬入）完了' && oppProductList[j].oppProduct.Delivery__r.DeliveryStatus__c!='出庫準備完了'){
	        	oppProductList[j].selectedFlg = flg;
	        }
        }
        component.set("v.oppProductList",oppProductList);
    },
    
    /** 
     * 新規商品ボタンを押すと、商品一覧のバックグラウンドカラーをクリアする。
     */
    clearColor:function(component,event,helper){
    	if ($A.util.isEmpty(component.get("v.productId"))) {
    		var target = $(".tableTrMove");
    		console.log(target);

    		var childNodes = target[0].childNodes;
    		console.log(childNodes);
    		for (var i = 0 ; i < childNodes.length ; i++) {
    			console.log(childNodes[i].style.backgroundColor);
    			childNodes[i].style.backgroundColor = "";
    		}
    	}
    },
})