/** 
 * 更新、配送、仕入詳細レコード画面において、在庫案件表示コンポーネント向けのコントローラ
 */
public with sharing class ContractProductEditListController {
    @AuraEnabled
    public static InitInfo getInitInfo(String Id, String sObjectName){
    	InitInfo initInfo = new InitInfo();
    	
    	Agreement__c agreement =  null;
    	
    	String sql = 'SELECT Id,Name,OpportunityProduct__r.InstallationLocation__r.Name,InventoryProduct__c';
        sql += ' ,InventoryProduct__r.Name, OpportunityProduct__r.Name , MakerPrice__c,Rank__c,SellingRate__c';
        sql += ' ,UnitPriceLease__c , EachMonthlyLeaseFee__c , OpportunityProduct__r.PurchaseRate__c , SalesCost__c';
        sql += ' ,InventoryProduct__r.CurrentStatus__c , OpportunityProduct__r.HaisouType__c , Status__c,DamageMoney__c';
        sql += ' ,OpportunityProduct__r.ProductType__c,ProductFlag__c,OpportunityProduct__r.Purchase__r.Status__c , Agreement__c';
        sql += ' ,KENSpecialDiscountFlag__c ,Haisou__r.DeliveryStatus__c,Haisou__r.DeliveryType__c, DiscountFlag__c,SetupFeeFlag__c';
        sql += '  FROM InventoryOpportunityProduct__c';
        
        if (sObjectName == 'Purchase__c') {
            sql += '  WHERE OpportunityProduct__r.Purchase__c = :Id AND KENSpecialDiscountFlag__c = FALSE ';
            sql += '  AND SetupFeeFlag__c = FALSE AND  DiscountFlag__c = FALSE';
        } else if (sObjectName == 'Agreement__c') {
            sql += '  WHERE Agreement__c = :Id AND DiscountFlag__c = FALSE AND KENSpecialDiscountFlag__c = FALSE AND SetupFeeFlag__c = FALSE';
            agreement = PdfGeneratorController.getAgreementById(Id);
            initInfo.agreement = agreement;
        } else if (sObjectName == 'Delivery__c'){
            sql += '  WHERE Haisou__c = :Id AND DiscountFlag__c = FALSE AND KENSpecialDiscountFlag__c = FALSE AND HaisouType__c != \'顧客直送\'';
        }
        
        sql += ' ORDER BY OpportunityProduct__r.LocationNo__c NULLS LAST, OpportunityProduct__r.InstallationLocation__c NULLS LAST ,';
        sql += ' SetupFeeFlag__c,OpportunityProduct__r.SortNo__c NULLS LAST ,CreatedDate';
    	
    	List<InventoryOpportunityProduct__c> invOppProducts = Database.query(sql);
    	
    	List<InvOppProduct> invOppProductList = new List<InvOppProduct>();
    	
    	for (InventoryOpportunityProduct__c invOppProduct : invOppProducts) {
    	    InvOppProduct newInvOppProduct = new InvOppProduct();
    	    newInvOppProduct.selectedFlg = false;
    	    if (sObjectName == 'Agreement__c' 
    	                 && (agreement.Status__c == '契約解除済' || agreement.Status__c == '契約解除待ち' || agreement.Status__c == '契約更新済')
    	                 && invOppProduct.Status__c == '解約') {
                initInfo.deleteFlag = true;
            }
    	    newInvOppProduct.invOppProduct = invOppProduct;
    	    invOppProductList.add(newInvOppProduct);
    	}
    	initInfo.invOppProducts = invOppProductList;
    	
        return initInfo;
    }
    
    /** 
     * 保存処理
     * 1.リース、解約、買取の場合、そのまま保存。
     * 2.配送において、保存ボタンを押すの場合、ダメージ料金を集計する。
     * 3.メンテ済の場合、そのまま保存。
     */ 
    @AuraEnabled
    public static void updateInvOppProduct(List<InventoryOpportunityProduct__c> invOppProductList , Id id , String KBN){
    	//在庫案件商品を無条件に更新する。
    	update invOppProductList;
    	
        if (KBN == '' || KBN == 'メンテ済') {
            //配送情報を取得
            Delivery__c delivery = [SELECT Id,Name,DamageMoneySum__c,Agreement__c
                                    FROM Delivery__c 
                                    WHERE Id = :id];

            if (KBN == '') {    //搬出配送において、保存ボタンの場合
                //在庫リスト
                List<InventoryProduct__c> updateInvProducts = new List<InventoryProduct__c>();
                
                Decimal totalDamgeMoney = 0;
                for (InventoryOpportunityProduct__c invOppProduct : invOppProductList) {
                    //ダメージ料金の集計
                    totalDamgeMoney += invOppProduct.DamageMoney__c != null ? invOppProduct.DamageMoney__c:0;
                    //ランクを更新
                    if ( invOppProduct.InventoryProduct__c != null) {
                        InventoryProduct__c invProduct = new InventoryProduct__c();
                        invProduct.Id = invOppProduct.InventoryProduct__c;
                        invProduct.Rank__c = invOppProduct.Rank__c;
                        //invProduct.SellingRate__c = invOppProduct.SellingRate__c;
                        updateInvProducts.add(invProduct);
                    }
                }
                update updateInvProducts;
                
                //集計したダメージ料金を配送に更新
                delivery.DamageMoneySum__c = totalDamgeMoney;
                update delivery;
            }

            if (KBN == 'メンテ済') {
                //更新用在庫商品リスト
                List<InventoryProduct__c> invProducts = new List<InventoryProduct__c>();
                //在庫商品のステータスを「在庫」「メンテ済」に更新する。
                for (InventoryOpportunityProduct__c invOppProduct : invOppProductList) {
                    if (invOppProduct.InventoryProduct__c != null) {
                        InventoryProduct__c invProduct = new InventoryProduct__c();
                        invProduct.Id = invOppProduct.InventoryProduct__c;
                        invProduct.CurrentStatus__c = '在庫';
                        invProduct.CurrentStatusAuxiliary__c = 'メンテ済';
                        invProducts.add(invProduct);
                    }
                }
                update invProducts;
                //「メンテ済、リース中、買取」以外の商品を取得。
                List<InventoryOpportunityProduct__c> deliveryEndInvOppProducts = [SELECT Id,Name 
                                                                                  FROM InventoryOpportunityProduct__c 
                                                                                  WHERE Agreement__c = :delivery.Agreement__c
                                                                                  AND (Status__c != 'メンテ済' AND Status__c != 'リース中' AND Status__c != '買取')
                                                                                  AND HaisouType__c = '入庫'
                                                                                  AND DiscountFlag__c = FALSE
                                                                                  AND KENSpecialDiscountFlag__c = FALSE
                                                                                  AND SetupFeeFlag__c = FALSE];
            
                //なしの場合、TOBOを作成して、営業担当者へ連絡する。
                if (deliveryEndInvOppProducts.size() == 0) {
                    Task task = new Task();
                    task.WhatId = delivery.Agreement__c;
                    task.status = 'In Progress';
                    task.description = 'メンテ済のお知らせ';
                    task.Priority = 'High';
                    task.Subject = '入庫した商品を全部メンテ済となったため、保証金返金処理を引き続きよろしくお願いいたします。';
                    insert task;
                }
            }
        }
    }
    
    /** 
     * 仕入において、入庫処理
     */ 
    @AuraEnabled
    public static void storing(String id , List<InventoryOpportunityProduct__c> invOppProducts) {
    	system.debug(id);
        Purchase__c purchase = [SELECT Id,Name,
                                (SELECT Id,Name,PurchaseStatus__c,Quantity__c FROM OpporProduct__r WHERE PurchaseStatus__c != '在庫')
                                FROM Purchase__c 
                                WHERE Id = :id];
        
        //在庫商品の入庫リスト
        List<InventoryProduct__c> invProducts = new List<InventoryProduct__c>();
        
        //在庫案件商品のステータスを「在庫」に更新する。且   在庫商品のステータスを「在庫」に更新する。
        for (InventoryOpportunityProduct__c invOppProduct : invOppProducts) {
        	//在庫案件商品のステータス
        	invOppProduct.Status__c = '在庫';
        	//在庫商品のステータス
        	if (invOppProduct.InventoryProduct__c != null) {
        	    InventoryProduct__c invProduct = new InventoryProduct__c();
        	    invProduct.Id = invOppProduct.InventoryProduct__c;
        	    invProduct.CurrentStatus__c = '在庫';
        	    invProduct.CurrentStatusAuxiliary__c = null;
                invProducts.add(invProduct);
        	}
        }
        update invOppProducts;
        update invProducts;
        
        //仕入のステータスを「入庫済」に更新する。
        List<InventoryOpportunityProduct__c> purchaseEndInvOppProducts = [SELECT Id,Name 
                                                                          FROM InventoryOpportunityProduct__c 
                                                                          WHERE OpportunityProduct__r.Purchase__c = :id
                                                                          AND Status__c != '在庫'
                                                                          AND HaisouType__c = '入庫'
                                                                          AND DiscountFlag__c = FALSE
                                                                          AND KENSpecialDiscountFlag__c = FALSE];
        if (purchaseEndInvOppProducts.size() == 0) {
            purchase.Status__c = '入庫済';
            update purchase;
        }
    }
    
    /** 
     * 配送において、出庫準備完了処理
     */ 
    @AuraEnabled
    public static void deliveryTehai(String id , List<InventoryOpportunityProduct__c> invOppProducts) {
        Delivery__c delivery = [SELECT Id,Name,DeliveryStatus__c,
                                (SELECT Id,Name,Status__c FROM InventoryOpportunityProduct__r 
                                        WHERE DiscountFlag__c = FALSE AND KENSpecialDiscountFlag__c = FALSE AND HaisouType__c != '顧客直送')
                                FROM Delivery__c 
                                WHERE Id = :id];
        
        //在庫案件商品のステータスを「出庫準備完了」に更新する。
        for (InventoryOpportunityProduct__c invOppProduct : invOppProducts) {
        	invOppProduct.Status__c = '出庫準備完了';
        }
        update invOppProducts;
        
        //「出庫準備完了」以外の商品を取得。
        List<InventoryOpportunityProduct__c> deliveryEndInvOppProducts = getInvOppProducts(id,'出庫準備完了');
        
        //配送のステータスを「出庫準備完了」に更新する。
        if (deliveryEndInvOppProducts.size() == 0) {
            delivery.DeliveryStatus__c = '出庫準備完了';
            update delivery;
        }
    }

    /** 
     * 配送において、D/L（搬入）完了或は搬出済み処理
     */ 
    @AuraEnabled
    public static void delivery(String id , List<InventoryOpportunityProduct__c> invOppProducts) {
        Delivery__c delivery = [SELECT Id,Name,DeliveryStatus__c,Estimate__r.Opportunity__r.Id,Estimate__r.RecordType.Name,DeliveryType__c
                                FROM Delivery__c 
                                WHERE Id = :id];
        
        //在庫商品の配送み用リスト
        List<InventoryProduct__c> invProducts = new List<InventoryProduct__c>();
        
        if (delivery.DeliveryType__c == '搬入') {
            //在庫案件商品のステータスを「在庫」に更新する。且   在庫商品のステータスを「在庫」に更新する。
            for (InventoryOpportunityProduct__c invOppProduct : invOppProducts) {
                //在庫案件商品のステータス
                if (delivery.Estimate__r.RecordType.Name == 'リース') {
                    invOppProduct.Status__c = 'リース中';
                } else if (delivery.Estimate__r.RecordType.Name == '販売') {
                    invOppProduct.Status__c = '販売済';
                }
                if (invOppProduct.InventoryProduct__c != null) {
                    //在庫商品のステータス
                    InventoryProduct__c invProduct = new InventoryProduct__c();
                    invProduct.Id = invOppProduct.InventoryProduct__c;
                    if (delivery.Estimate__r.RecordType.Name == 'リース') {
                        invProduct.CurrentStatus__c = 'リース中';
                        invProduct.CurrentStatusAuxiliary__c = null;
                    } else if (delivery.Estimate__r.RecordType.Name == '販売') {
                        invProduct.CurrentStatus__c = '除却';
                        invProduct.CurrentStatusAuxiliary__c = '販売済';
                    }
                    invProducts.add(invProduct);
                }
            }
            update invOppProducts;
            update invProducts;
            
            //「D/L（搬入）完了」以外の商品を取得。
            List<InventoryOpportunityProduct__c> deliveryEndInvOppProducts ;
            
            if (delivery.Estimate__r.RecordType.Name == 'リース') {
                deliveryEndInvOppProducts = getInvOppProducts(id,'リース中');
            } else if (delivery.Estimate__r.RecordType.Name == '販売') {
                deliveryEndInvOppProducts = getInvOppProducts(id,'販売済');
            }
            
            delivery.DeliveryDate__c = Date.today();
            //配送のステータスを「D/L（搬入）完了」に更新する。
            if (deliveryEndInvOppProducts != null && deliveryEndInvOppProducts.size() == 0) {
                delivery.DeliveryStatus__c = 'D/L（搬入）完了';
                //D/L（搬入）完了案件更新
                updateOpp(delivery.Estimate__r.Opportunity__r.Id,delivery.Estimate__r.RecordType.Name);
            }
            update delivery;
        } else if (delivery.DeliveryType__c == '搬出') {
            //在庫商品の現状区分を「在庫」、現状補助区分を「未メンテ」に更新する。
            for (InventoryOpportunityProduct__c invOppProduct : invOppProducts) {
                //在庫案件商品のステータス
                invOppProduct.Status__c = '未メンテ';
                if (invOppProduct.InventoryProduct__c != null) {
                    //在庫商品のステータス
                    InventoryProduct__c invProduct = new InventoryProduct__c();
                    invProduct.Id = invOppProduct.InventoryProduct__c;
                    invProduct.CurrentStatus__c = '在庫';
                    invProduct.CurrentStatusAuxiliary__c = '未メンテ';
                    //HOLD解除
                    invProduct.HOLD__c = false;
                    invProduct.Haisou__c = null;
                    invProduct.Estimate__c = null;
                    invProduct.Oppotunity__c = null;
                    invProduct.Agreement__c = null;    //契約
                    invProduct.HOLDUser__c = null;
                    invProducts.add(invProduct);
                }
            }
            update invOppProducts;
            update invProducts;
            
            //「搬出済」以外の商品を取得。
            List<InventoryOpportunityProduct__c> deliveryEndInvOppProducts = getInvOppProducts(id,'未メンテ');
                                                                              
            delivery.DeliveryDate__c = Date.today();
            //配送のステータスを「搬出済」に更新する。
            if (deliveryEndInvOppProducts.size() == 0) {
                delivery.DeliveryStatus__c = '搬出済';
            }
            update delivery;
        }
    }
    
    /** 
     * 配送下の在庫案件商品を取得する。
     * id 配送ID
     * Status 配送ステータス
     */
    public static List<InventoryOpportunityProduct__c> getInvOppProducts(Id id , String Status) {
        List<InventoryOpportunityProduct__c> deliveryEndInvOppProducts = [SELECT Id,Name 
                                                                          FROM InventoryOpportunityProduct__c 
                                                                          WHERE Haisou__c = :id
                                                                          AND Status__c != :Status
                                                                          AND HaisouType__c = '入庫'
                                                                          AND DiscountFlag__c = FALSE
                                                                          AND KENSpecialDiscountFlag__c = FALSE];
        
        return deliveryEndInvOppProducts;
    }
    
    /** 
     * D/L（搬入）完了案件更新
     * ids 案件IDリスト
     */
    public static void updateOpp(Id id , String recordTypeName) {
        system.debug('D/L（搬入）完了案件更新');
        Opportunity opp = new Opportunity();
        opp.Id = id;
        if (recordTypeName == 'リース') {
            opp.StageName = 'リース中';
        } else if (recordTypeName == '販売') {
            opp.StageName = '成約';
        }
        update opp;
    }
	    
    /** 
     * 商品表示リスト
     */ 
    public class InvOppProduct {
    	/**
         * 選択フラグ
         */
    	@AuraEnabled
        public boolean selectedFlg;
        
        /**
         * 在庫案件商品オブジェクト
         */
        @AuraEnabled
        public InventoryOpportunityProduct__c invOppProduct {get;set;}
    }
    
    /** 
     * 初期化情報
     */ 
    public class InitInfo {
    	/**
         * 契約情報
         */
    	@AuraEnabled
        public Agreement__c agreement;
        
    	/**
         * 除却情報
         */
    	@AuraEnabled
        public Boolean deleteFlag;
        
        /**
         * 商品表示リスト
         */
        @AuraEnabled
        public List<InvOppProduct> invOppProducts {get;set;}
    }
}