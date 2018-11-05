public class keiyakuPDFController {
    public Agreement__c agreement{get;set;}
    public Account  account {get;set;}
   	public String pdftype {get;set;}
   	public String ParentAgreementName {get;set;}
    public keiyakuPDFController(){
    	String agreementId = ApexPages.currentPage().getParameters().get('id');
    	pdftype=ApexPages.currentPage().getParameters().get('pdfType');
        system.debug('agreementId: '+agreementId);
        system.debug('pdftype: '+pdftype);
        getMiumori(agreementId);
        //pdftype='Oboegaki';
        //getMiumori('a0A0k00000705rdEAA');
    }

    public void getMiumori(String AgreementId){
        agreement=[SELECT
                  		Name,                       //お問合せNo.
                  		Contractors__c,             //契約先
                  		TeiketuDay__c,              //締結日
                  		PropertyAddress__c,         //場所（物件名）住所
                  		PropertyHomeNo__c,          //物件名・部屋番号
                  		UserNew__c,                 //使用者
                  		LeaseStart__c,              //リース開始日
                  		LeaseEnd__c,                //リース終了日
                  		MonthlyLeaseFeeTotal2__c,   //月額リース料（集計）
                  		MonthlyLeaseFeeTax__c,      //月額リース料消費税
                  		PaymentMethod__c,  				//支払方法
                  		Estimate__r.DeliveryFeeSum__c,  //搬出入手数料(集計)
                  		Estimate__r.SetupFeeSum__c,     //取付工事費(集計)
                  		Estimate__r.OtherFeeSum__c,     //その他費用(集計)
                  		Estimate__r.OtherFeeSumPDF__c,  //その他費用PDF用(値引き含む)
                  		
                        CostSum2__c,                        //諸費用総額(集計)
                        CostSum3__c,                        //諸費用総額(集計、値引き含む)
                  		CostTotalTax__c,                    //諸費用総額消費税
                  		hoshokin__c,                        //保証金
                  		shokaileasefee__c,                  //(非表示)初回リース料金     
                  		SyokaiLeaseTax__c,                  //(非表示)初回リース料金消費税
                  		TotalAcceptanceUponContract__c,     //(非表示)契約時申受金合計
                  		DepositMonth__c,		            //保証金月数（ヶ月）
                  		Estimate__r.FirstKikanTo1__c,		//初回リース料期間（TO）
                  		ParentAgreement__r.Name,            //元契約     

                  		LeaseMonth__c,						//リース月数
                  		MonthlyLeaseRate__c,				//月額リース料率
                  		ProductListPriceTotal__c,           //標準小売価格(集計)
                  		AmountPercentLeaseTotal__c,         //計算価値価格(集計)                 		
						          
                               (SELECT 
                     		             InventoryProduct__r.Name, 						//「在庫」.(非表示)在庫番号
                     		             OpportunityProduct__r.U_N__c, 				    //「商品」.(非表示)U/N
                     		             OpportunityProduct__r.Name,					//「商品」.商品名
                     		             OpportunityProduct__r.Maker__c,                //「商品」.メーカー
                     		             OpportunityProduct__r.ModelTotal__c,           //「商品」.型番 (自動)
                     		             MakerPrice__c,							        //標準小売価格(単価)
                     		             UnitPriceLease__c,						        //計算価値価格
                     		             EachMonthlyLeaseFee__c				       	    //月額リース料
                               FROM InventoryOpportunityProduct__r
                               WHERE ProductFlag__c = true
                               ORDER BY OpportunityProduct__r.LocationNo__c NULLS LAST, OpportunityProduct__r.InstallationLocation__c NULLS LAST ,
                                        SetupFeeFlag__c,OpportunityProduct__r.SortNo__c NULLS LAST ,CreatedDate)
                  FROM Agreement__c
                  WHERE id=:AgreementId
        ];
        if(agreement!=null){
        	ParentAgreementName=agreement.ParentAgreement__r.Name;
        }
        system.debug('agreement: '+agreement);
						/* 田さんからロジックをもらう
　　　                   田さんのロジックは共通クラスに移動してください。
                           Opportunity__r.Account.Name,Opportunity__r.PropertyName__r.BillingState,
                           Opportunity__r.PropertyName__r.BillingCity,Opportunity__r.PropertyName__r.BillingStreet,
                           Opportunity__r.PropertyName__r.Name,Opportunity__r.Account.PaymentMethod__c,
*/
                account= CommonUntil.getOwnerAccount();        
    }

}