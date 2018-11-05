/** 
 * 見積、更新詳細レコード画面において、配送の搬入、搬出
 */
public class DeliveryController {
	
	/** 
     * 配送ポップアップを開くとき、選択リストを作成
     * Param estimateId 見積ID
     */ 
	@AuraEnabled
    public static List<CommonUntil.Option> getDeliverys(Id id , String sObjectName) {
    	//見積下、配送を全部取得する。
    	List<Delivery__c> deliverys;
    	if (sObjectName == 'Agreement__c') {
    	    deliverys = [SELECT Id,Name,DeliveryPrepareDay__c
    	                               FROM Delivery__c 
    	                               WHERE Agreement__c = :id
    	                               AND ( DeliveryStatus__c = '依頼済' OR DeliveryStatus__c = null)];
    	} else {
    	    deliverys = [SELECT Id,Name,DeliveryPrepareDay__c
    	                               FROM Delivery__c 
    	                               WHERE Estimate__c = :id
    	                               AND ( DeliveryStatus__c = '依頼済' OR DeliveryStatus__c = null)];
    	}
    	 
    	List<CommonUntil.Option> options = new List<CommonUntil.Option>();
    	//配送より、選択肢を作成
    	for (Delivery__c delivery : deliverys) {
    	    CommonUntil.Option option = new CommonUntil.Option();
    	    if (delivery.DeliveryPrepareDay__c == null) {
    	        option.label = delivery.Name;
    	    } else {
    	        option.label = delivery.Name + ' ' + String.valueOf(delivery.DeliveryPrepareDay__c);
    	    }
    	    option.value = delivery.Id;
            
            options.add(option);
    	}
    	//「新規配送作成」選択肢を作成
    	CommonUntil.Option option = new CommonUntil.Option();
    	option.label = '新規配送作成';
        option.value = 'new';
        options.add(option);
        return options;
    }
    
    /** 
     * 配送作成（搬入）
     * Param productList チェックされた商品リスト
     * Param typeId 新規作成或は既存の配送に入りたい
     * Param deliveryDate 配送依頼日
     * Param welcomekit welcomekit
     * Param tachiaiPerson 立会者
     * Param customersRemarks 特記事項
     */ 
    @AuraEnabled
    public static String createDeliveryIn (List<OpportunityProduct__c> productList ,String typeId ,
                                           String deliveryDate,Boolean welcomekit, String tachiaiPerson , String customersRemarks){

        //配送の作成
        Delivery__c delivery = new Delivery__c();
        delivery.DeliveryPrepareDay__c = (DateTime) JSON.deserialize('"' + deliveryDate + '"', DateTime.class);
        delivery.DeliveryRequestDate__c = Date.today();
        delivery.Welcome_kit__c = welcomekit;
        delivery.TachiaiPerson__c = (String.isBlank(tachiaiPerson)?null:tachiaiPerson);
        delivery.CustomersRemarks__c = customersRemarks;
        delivery.DeliveryType__c = '搬入';
        
        //既存の配送を選択する場合
        if (typeId != 'new') {
        	//配送中に、元商品リスを取得
        	List<OpportunityProduct__c> originProductList = [SELECT Id,Name,Delivery__c FROM  OpportunityProduct__c WHERE Delivery__c = :typeId];
        	
        	//在庫案件商品取得
            List<InventoryOpportunityProduct__c> originInvOppProductList = CommonUntil.getInvOppProduct(originProductList);
        	
        	//商品、在庫案件商品、在庫商品の配送を更新
        	CommonUntil.updateRelDelivery(originProductList,originInvOppProductList,null);
        	
        	delivery.DeliveryStatus__c = '依頼済';
        	delivery.Id = typeId;
        	update delivery;
        } else {    //新規配送作成の場合
        	delivery.DeliveryStatus__c = '依頼済';
        	delivery.Estimate__c = productList[0].Estimates__c;
        	Estimate__c mitumori = CommonUntil.getEstimateById(productList[0].Estimates__c);
        	delivery.Agreement__c = mitumori.Estimate__r[0].Id;
            insert delivery;
        }
        
        //商品より、在庫案件商品を取得
        List<InventoryOpportunityProduct__c> invOppProductList = CommonUntil.getInvOppProduct(productList);
        
        //商品、在庫案件商品、在庫商品の配送を更新
        CommonUntil.updateRelDelivery(productList,invOppProductList,delivery.Id);
       
        return delivery.Id;
    }
    
    /** 
     * 配送作成（搬出）
     * Param productList チェックされた在庫案件商品リスト
     * Param deliveryDate 配送依頼日
     * Param welcomekit welcomekit
     * Param tachiaiPerson 立会者
     * Param customersRemarks 特記事項
     */ 
    @AuraEnabled
    public static String createDeliveryOut (List<InventoryOpportunityProduct__c> productList ,String typeId ,
                                            String deliveryDate,Boolean welcomekit, String tachiaiPerson , String customersRemarks){

        //配送の作成
        Delivery__c delivery = new Delivery__c();
        delivery.DeliveryPrepareDay__c = (DateTime) JSON.deserialize('"' + deliveryDate + '"', DateTime.class);
        delivery.DeliveryRequestDate__c = Date.today();
        delivery.Welcome_kit__c = welcomekit;
        delivery.TachiaiPerson__c = (String.isBlank(tachiaiPerson)?null:tachiaiPerson);
        delivery.CustomersRemarks__c = customersRemarks;
        delivery.DeliveryType__c = '搬出';
        //既存の配送を選択する場合
        if (typeId != 'new') {
        	//配送中に、元在庫案件商品リスを取得
        	List<InventoryOpportunityProduct__c> originInvOppProductList = [SELECT Id,Name,Haisou__c FROM InventoryOpportunityProduct__c WHERE Haisou__c = :typeId];
        	
        	//商品、在庫案件商品、在庫商品の配送を更新
        	CommonUntil.updateRelDelivery(new List<OpportunityProduct__c>(),originInvOppProductList,null);
        	
        	delivery.DeliveryStatus__c = '依頼済';
        	delivery.Id = typeId;
        	update delivery;
        } else {    //新規配送作成の場合
        	delivery.DeliveryStatus__c = '依頼済';
        	delivery.Agreement__c = productList[0].Agreement__c;
            insert delivery;
        }
        
        //商品、在庫案件商品、在庫商品の配送を更新
        CommonUntil.updateRelDelivery(new List<OpportunityProduct__c>(),productList,delivery.Id);
        
        Task task = new Task();
        task.WhatId = delivery.Agreement__c;
        task.status = 'In Progress';
        task.description = '配送のお知らせ';
        task.Priority = 'High';
        task.Subject = '回収予定の商品を配送に入れ、ご確認をお願い致します。';
        insert task;

        return delivery.Id;
    }
    
    /** 
     * 「次へ」ボタンを押して、選択された配送の情報を取得する。
     * Param deliveryId 配送ID
     */ 
	@AuraEnabled
    public static Delivery__c getDeliveryInfo (Id deliveryId) {
    	Delivery__c delivery = [SELECT Id,Name,DeliveryPrepareDay__c,CustomersRemarks__c,DeliveryType__c
    	                        FROM Delivery__c 
    	                        WHERE Id = :deliveryId];
        return delivery;
    }
}