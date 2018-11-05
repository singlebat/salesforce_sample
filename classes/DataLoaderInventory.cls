public with sharing class DataLoaderInventory {
    
    /** 
     * 商品登録処理を行う。
     */ 
	@AuraEnabled
	public static List<InventoryOpportunityProduct__c> productSelected(){
		

	    //新規商品リスト
        List<OpportunityProduct__c> oppProducts = new List<OpportunityProduct__c>();
        //新規在庫案件商品リスト
        List<InventoryOpportunityProduct__c> newInvOppProductList = new List<InventoryOpportunityProduct__c>();
	    //SQLを作成
		String sqlQuery = 'SELECT Id,Name,PictureURL1__c,ProductName__c,CurrentStatus__c,SetNo__c,InstallationLocation__c,';
		sqlQuery += ' CurrentStatusAuxiliary__c,ValuePrice__c,PurchaseName__c,ProductMaster__c,RankRate__c,';
		sqlQuery += ' SellingRate2__c,PurchaseRate__c,Rank__c,nyukoyoteibi__c,ReceiptDate__c,(SELECT Id FROM CombinedAttachments),';
		sqlQuery += ' ProductMaster__r.Maker__r.Name,ProductMaster__r.ListPrice__c,ModelNumber__c,';
		sqlQuery += ' Height__c,Height2__c,Width__c,Depth__c,Diameter__c,Size__c,ProductPrice__c,';
		sqlQuery += ' Specification1__c,Specification2__c,Specification3__c,Specification4__c,';
		sqlQuery += ' Specification5__c,Specification6__c,Specification7__c,Specification8__c,SalesCost__c,';
		sqlQuery += ' Accessories__c, AccessorieMod1__c,AccessorieSp1__c,AccessorieNum1__c,AccessorieSize1__c,';
		sqlQuery += ' Accessories2__c,AccessorieMod2__c,AccessorieSp2__c,AccessorieNum2__c,AccessorieSize2__c,';
		sqlQuery += ' Accessories3__c,AccessorieMod3__c,AccessorieSp3__c,AccessorieNum3__c,AccessorieSize3__c,';
		sqlQuery += ' Estimate__c,Agreement__c,Haisou__c,MigrationID__c';
		sqlQuery += ' FROM InventoryProduct__c';
		sqlQuery += ' WHERE MigrationID__c !=  \'\'';
		sqlQuery += ' AND MigrationID__c != NULL ';
		system.debug(sqlQuery);
        List<InventoryProduct__c> inventoryProducts = Database.query(sqlQuery);
        system.debug(inventoryProducts);
        
        //在庫商品の更新 HOLDになる
        for (InventoryProduct__c updateInProduct : inventoryProducts) {
            if ((updateInProduct.Estimate__c != '' && updateInProduct.Agreement__c == '') || 
                (updateInProduct.Estimate__c != '' && updateInProduct.Agreement__c != '')){ 
            	ID estimate = updateInProduct.Estimate__c;
            	System.debug('Estimate__c' + estimate);
		        //見積情報取得
		        Estimate__c estimateObj = [SELECT Id,Name,Opportunity__c,CreatedById,
		                                          RecordType.Name,MonthlyLeaseRate__c,
		                                         // MigrationID__c,
		                                          (SELECT Id FROM rel_Delivery__r),
		                                          (SELECT Id FROM Estimate__r)
		                                   FROM Estimate__c
		                                   WHERE Id = :estimate
		                                   ];
		        system.debug(estimateObj);
		        
			     //商品を作成
			    OpportunityProduct__c opportunityProduct = new OpportunityProduct__c();
		        opportunityProduct.SetNo__c = updateInProduct.SetNo__c;               //セット番号  
		        opportunityProduct.Product__c = updateInProduct.ProductMaster__c;     //商品マスタ
		        opportunityProduct.name  = updateInProduct.ProductName__c;            //商品名
		        opportunityProduct.ProductType__c = '在庫品';                          //商品区分
		        opportunityProduct.Rank__c  = updateInProduct.Rank__c;                //ランク
		        opportunityProduct.RankRate__c  = updateInProduct.RankRate__c;        //ランク率
		        opportunityProduct.InstallationLocation__c  = updateInProduct.InstallationLocation__c;    //設置場所
		        opportunityProduct.Quantity__c = 1;                                     //数量
		        opportunityProduct.MakerPrice__c = updateInProduct.ProductPrice__c;    //標準小売価格(単価)
		        if (updateInProduct.SellingRate2__c != null) {
		            opportunityProduct.SellingRate__c = updateInProduct.SellingRate2__c;//販売率
		        }
		        if (estimateObj.RecordType.Name == 'リース') {
		            opportunityProduct.UnitPriceLease__c = updateInProduct.ValuePrice__c;          //計算価値価格
		            opportunityProduct.MonthlyLeaseRate__c =  estimateObj.MonthlyLeaseRate__c;      //月額リース料率
		        }
		        if (estimateObj.RecordType.Name == '販売') {
		            opportunityProduct.UnitPriceLease__c =  updateInProduct.ValuePrice__c;       //計算価値価格
		        }
		        
		        opportunityProduct.ModelNumber__c = updateInProduct.ModelNumber__c;    //型番
		        opportunityProduct.Height__c = updateInProduct.Height__c;              //高さ
		        opportunityProduct.Width__c = updateInProduct.Width__c;                //幅
		        opportunityProduct.Depth__c = updateInProduct.Depth__c;                //奥行
		        opportunityProduct.Height2__c = updateInProduct.Height2__c;            //高さⅡ
		        opportunityProduct.Diameter__c = updateInProduct.Diameter__c;          //直径
		        opportunityProduct.Accessories__c = updateInProduct.Accessories__c;          //付属品1
		        opportunityProduct.AccessorieMod1__c = updateInProduct.AccessorieMod1__c;    //付属品1型番
		        opportunityProduct.AccessorieSp1__c = updateInProduct.AccessorieSp1__c;      //付属品1仕様
		        opportunityProduct.AccessorieNum1__c = updateInProduct.AccessorieNum1__c;    //付属品1数量
		        opportunityProduct.AccessorieSize1__c = updateInProduct.AccessorieSize1__c;  //付属品1サイズ
		        opportunityProduct.Accessories2__c = updateInProduct.Accessories2__c;        //付属品2
		        opportunityProduct.AccessorieMod2__c = updateInProduct.AccessorieMod2__c;    //付属品2型番
		        opportunityProduct.AccessorieSp2__c = updateInProduct.AccessorieSp2__c;      //付属品2仕様
		        opportunityProduct.AccessorieNum2__c = updateInProduct.AccessorieNum2__c;    //付属品2数量
		        opportunityProduct.AccessorieSize2__c = updateInProduct.AccessorieSize2__c;  //付属品2サイズ
		        opportunityProduct.Accessories3__c = updateInProduct.Accessories3__c;        //付属品3
		        opportunityProduct.AccessorieMod3__c = updateInProduct.AccessorieMod3__c;    //付属品3型番
		        opportunityProduct.AccessorieSp3__c = updateInProduct.AccessorieSp3__c;      //付属品3仕様
		        opportunityProduct.AccessorieNum3__c = updateInProduct.AccessorieNum3__c;    //付属品3数量
		        opportunityProduct.AccessorieSize3__c = updateInProduct.AccessorieSize3__c;  //付属品3サイズ
		        opportunityProduct.Specification1__c = updateInProduct.Specification1__c;       //仕様１
		        opportunityProduct.Specification2__c = updateInProduct.Specification2__c;       //仕様２
		        opportunityProduct.Specification3__c = updateInProduct.Specification3__c;       //仕様３
		        opportunityProduct.Specification4__c = updateInProduct.Specification4__c;       //仕様４
		        opportunityProduct.Specification5__c = updateInProduct.Specification5__c;       //仕様５
		        opportunityProduct.Specification6__c = updateInProduct.Specification6__c;       //仕様６
		        opportunityProduct.Specification7__c = updateInProduct.Specification7__c;       //仕様７
		        opportunityProduct.Specification8__c = updateInProduct.Specification8__c;       //仕様８
		        opportunityProduct.SalesCost__c = 0;                                   //下代           
		        opportunityProduct.Estimates__c = estimateObj.Id;                      //見積
		        opportunityProduct.Contract__c = estimateObj.Estimate__r[0].Id;        //契約
		        opportunityProduct.PictureURL1__c = updateInProduct.PictureURL1__c;
		        //仕様書にないですが、一旦在庫品を選択して、配送の場合は必要があると思います。
		        opportunityProduct.HaisouType__c = '入庫';                             //配送区分
		        opportunityProduct.Delivery__c = estimateObj.rel_Delivery__r[0].Id;    //配送
		        //在庫品として登録した商品のステータスは在庫とする。
		        opportunityProduct.PurchaseStatus__c = '在庫';                         //商品ステータス
		        //商品一覧表示項目:在庫番号
		        opportunityProduct.InventoryProductNo__c = updateInProduct.Name;
		        //商品一覧表示項目:現状区分
		        opportunityProduct.CurrentStatus__c = updateInProduct.CurrentStatus__c;
		        // MigrationID_PM(在庫)
		        opportunityProduct.MigrationID_PM__c = updateInProduct.MigrationID__c;
		        // MigrationID_ES(見積)
		        //opportunityProduct.MigrationID_ES__c = estimateObj.MigrationID__c;
		        // MigrationID_AG(契約)
		        opportunityProduct.MigrationID_AG__c = updateInProduct.MigrationID_AC__c;
		        
	            // 商品リストへ格納する
	            oppProducts.add(opportunityProduct);
	            
	            system.debug(oppProducts);
	            
	            //在庫案件商品の追加
	            InventoryOpportunityProduct__c invOppProduct = new InventoryOpportunityProduct__c();
		        invOppProduct.InventoryProduct__c = updateInProduct.ID;        //在庫ID
		        invOppProduct.Haisou__c = estimateObj.rel_Delivery__r[0].Id;    //配送
		        invOppProduct.Agreement__c = estimateObj.Estimate__r[0].Id;     //更新
		        invOppProduct.RankRate__c = updateInProduct.RankRate__c;       //ランク率
		        invOppProduct.Rank__c = updateInProduct.Rank__c;               //ランク
		        invOppProduct.SalesCost__c = 0;     //下代
		        invOppProduct.UnitPriceLease__c = updateInProduct.ValuePrice__c;        //計算価値価格
		        invOppProduct.MonthlyLeaseRate__c = estimateObj.MonthlyLeaseRate__c;     //月額リース料率
		        invOppProduct.MakerPrice__c = updateInProduct.ProductPrice__c;          //標準小売価格(単価)
		        invOppProduct.Status__c = updateInProduct.CurrentStatus__c;             //ステータス
		        // MigrationID_PM(在庫)
		        invOppProduct.MigrationID_PM__c = updateInProduct.MigrationID__c;
		        // MigrationID_ES(見積)
		        //invOppProduct.MigrationID_ES__c = estimateObj.MigrationID__c;
		        // MigrationID_AG(契約)
		        invOppProduct.MigrationID_AG__c = updateInProduct.MigrationID_AC__c;
		        
	            newInvOppProductList.add(invOppProduct);
	            
	            updateInProduct.Oppotunity__c = estimateObj.Opportunity__c;      //案件
	            updateInProduct.Estimate__c = estimateObj.Id;                    //見積
	            updateInProduct.Agreement__c = estimateObj.Estimate__r[0].Id;    //更新
	            updateInProduct.HOLD__c = true;                                  //HOLD区分
	            updateInProduct.Haisou__c = estimateObj.rel_Delivery__r[0].Id;   //配送
	            updateInProduct.HOLDUser__c = estimateObj.CreatedById;           //HOLD担当者は見積所有者
            
            } else if (updateInProduct.Agreement__c != '' && updateInProduct.Estimate__c == ''){
            	ID Agreement = updateInProduct.Agreement__c;
            	System.debug('Agreement__c' + Agreement);
		        //見積情報取得
		        Agreement__c agreementObj = [select Id
		                                            ,MonthlyLeaseRate__c
		                                            ,Estimate__c
		                                            ,Estimate__r.MonthlyLeaseRate__c
		                                            ,Estimate__r.Opportunity__c
		                                            ,Estimate__r.CreatedById 
		                                      from Agreement__c
		                                      WHERE Id = :Agreement
		                                   ];
		        system.debug(agreementObj);
            	
                //商品を作成
			    OpportunityProduct__c opportunityProduct = new OpportunityProduct__c();
		        opportunityProduct.SetNo__c = updateInProduct.SetNo__c;               //セット番号  
		        opportunityProduct.Product__c = updateInProduct.ProductMaster__c;     //商品マスタ
		        opportunityProduct.name  = updateInProduct.ProductName__c;            //商品名
		        opportunityProduct.ProductType__c = '在庫品';                          //商品区分
		        opportunityProduct.Rank__c  = updateInProduct.Rank__c;                //ランク
		        opportunityProduct.RankRate__c  = updateInProduct.RankRate__c;        //ランク率
		        opportunityProduct.InstallationLocation__c  = updateInProduct.InstallationLocation__c;    //設置場所
		        opportunityProduct.Quantity__c = 1;                                     //数量
		        opportunityProduct.MakerPrice__c = updateInProduct.ProductPrice__c;    //標準小売価格(単価)
		        if (updateInProduct.SellingRate2__c != null) {
		            opportunityProduct.SellingRate__c = updateInProduct.SellingRate2__c;//販売率
		        }
	            opportunityProduct.UnitPriceLease__c = updateInProduct.ValuePrice__c;          //計算価値価格
	            opportunityProduct.MonthlyLeaseRate__c =  agreementObj.Estimate__r.MonthlyLeaseRate__c;      //月額リース料率
		        opportunityProduct.ModelNumber__c = updateInProduct.ModelNumber__c;    //型番
		        opportunityProduct.Height__c = updateInProduct.Height__c;              //高さ
		        opportunityProduct.Width__c = updateInProduct.Width__c;                //幅
		        opportunityProduct.Depth__c = updateInProduct.Depth__c;                //奥行
		        opportunityProduct.Height2__c = updateInProduct.Height2__c;            //高さⅡ
		        opportunityProduct.Diameter__c = updateInProduct.Diameter__c;          //直径
		        opportunityProduct.Accessories__c = updateInProduct.Accessories__c;          //付属品1
		        opportunityProduct.AccessorieMod1__c = updateInProduct.AccessorieMod1__c;    //付属品1型番
		        opportunityProduct.AccessorieSp1__c = updateInProduct.AccessorieSp1__c;      //付属品1仕様
		        opportunityProduct.AccessorieNum1__c = updateInProduct.AccessorieNum1__c;    //付属品1数量
		        opportunityProduct.AccessorieSize1__c = updateInProduct.AccessorieSize1__c;  //付属品1サイズ
		        opportunityProduct.Accessories2__c = updateInProduct.Accessories2__c;        //付属品2
		        opportunityProduct.AccessorieMod2__c = updateInProduct.AccessorieMod2__c;    //付属品2型番
		        opportunityProduct.AccessorieSp2__c = updateInProduct.AccessorieSp2__c;      //付属品2仕様
		        opportunityProduct.AccessorieNum2__c = updateInProduct.AccessorieNum2__c;    //付属品2数量
		        opportunityProduct.AccessorieSize2__c = updateInProduct.AccessorieSize2__c;  //付属品2サイズ
		        opportunityProduct.Accessories3__c = updateInProduct.Accessories3__c;        //付属品3
		        opportunityProduct.AccessorieMod3__c = updateInProduct.AccessorieMod3__c;    //付属品3型番
		        opportunityProduct.AccessorieSp3__c = updateInProduct.AccessorieSp3__c;      //付属品3仕様
		        opportunityProduct.AccessorieNum3__c = updateInProduct.AccessorieNum3__c;    //付属品3数量
		        opportunityProduct.AccessorieSize3__c = updateInProduct.AccessorieSize3__c;  //付属品3サイズ
		        opportunityProduct.Specification1__c = updateInProduct.Specification1__c;       //仕様１
		        opportunityProduct.Specification2__c = updateInProduct.Specification2__c;       //仕様２
		        opportunityProduct.Specification3__c = updateInProduct.Specification3__c;       //仕様３
		        opportunityProduct.Specification4__c = updateInProduct.Specification4__c;       //仕様４
		        opportunityProduct.Specification5__c = updateInProduct.Specification5__c;       //仕様５
		        opportunityProduct.Specification6__c = updateInProduct.Specification6__c;       //仕様６
		        opportunityProduct.Specification7__c = updateInProduct.Specification7__c;       //仕様７
		        opportunityProduct.Specification8__c = updateInProduct.Specification8__c;       //仕様８
		        opportunityProduct.SalesCost__c = 0;                                   //下代           
		        opportunityProduct.Estimates__c = agreementObj.Id;                      //見積
		        opportunityProduct.Contract__c = agreementObj.Id;        //契約
		        opportunityProduct.PictureURL1__c = updateInProduct.PictureURL1__c;
		        //仕様書にないですが、一旦在庫品を選択して、配送の場合は必要があると思います。
		        opportunityProduct.HaisouType__c = '入庫';                             //配送区分
		        opportunityProduct.Delivery__c = updateInProduct.Haisou__c;    //配送
		        //在庫品として登録した商品のステータスは在庫とする。
		        opportunityProduct.PurchaseStatus__c = '在庫';                         //商品ステータス
		        //商品一覧表示項目:在庫番号
		        opportunityProduct.InventoryProductNo__c = updateInProduct.Name;
		        //商品一覧表示項目:現状区分
		        opportunityProduct.CurrentStatus__c = updateInProduct.CurrentStatus__c;
		        
		        // MigrationID_PM(在庫)
		        opportunityProduct.MigrationID_PM__c = updateInProduct.MigrationID__c;
		        // MigrationID_AG(契約)
		        opportunityProduct.MigrationID_AG__c = updateInProduct.MigrationID_AC__c;
	            // 商品リストへ格納する
	            oppProducts.add(opportunityProduct);
	            
	            system.debug(oppProducts);
	            
	            //在庫案件商品の追加
	            InventoryOpportunityProduct__c invOppProduct = new InventoryOpportunityProduct__c();
		        invOppProduct.InventoryProduct__c = updateInProduct.ID;        //在庫ID
		        invOppProduct.Haisou__c = updateInProduct.Haisou__c;    //配送
		        invOppProduct.Agreement__c = agreementObj.Id;     //更新
		        invOppProduct.RankRate__c = updateInProduct.RankRate__c;       //ランク率
		        invOppProduct.Rank__c = updateInProduct.Rank__c;               //ランク
		        invOppProduct.SalesCost__c = 0;     //下代
		        invOppProduct.UnitPriceLease__c = updateInProduct.ValuePrice__c;        //計算価値価格
		        invOppProduct.MonthlyLeaseRate__c = agreementObj.MonthlyLeaseRate__c;     //月額リース料率
		        invOppProduct.MakerPrice__c = updateInProduct.ProductPrice__c;          //標準小売価格(単価)
		        invOppProduct.Status__c = updateInProduct.CurrentStatus__c;             //ステータス
		        // MigrationID_PM(在庫)
		        invOppProduct.MigrationID_PM__c = updateInProduct.MigrationID__c;
		        // MigrationID_AG(契約)
		        invOppProduct.MigrationID_AG__c = updateInProduct.MigrationID_AC__c;
	            newInvOppProductList.add(invOppProduct);
	            
	            updateInProduct.Oppotunity__c = agreementObj.Estimate__r.Opportunity__c;      //案件
	            updateInProduct.Estimate__c = agreementObj.Estimate__c;                    //見積
	            updateInProduct.Agreement__c = agreementObj.Id;    //更新
	            updateInProduct.HOLD__c = true;                                  //HOLD区分
	            updateInProduct.Haisou__c = updateInProduct.Haisou__c;   //配送
	            updateInProduct.HOLDUser__c = agreementObj.Estimate__r.CreatedById;           //HOLD担当者は見積所有者
            }
        	
        }
        update inventoryProducts;
        
        //商品のインサート
        insert oppProducts;
        
        //在庫案件商品は商品と紐づく。
        for (Integer i = 0 ; i <  oppProducts.size() ; i++) {
            newInvOppProductList[i].OpportunityProduct__c = oppProducts[i].Id;    //商品ID
        }
        //在庫案件商品のインサート
        insert newInvOppProductList;
        return newInvOppProductList;
	}
}