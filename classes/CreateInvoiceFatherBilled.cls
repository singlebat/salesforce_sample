public abstract class CreateInvoiceFatherBilled {
	 /**
     * 請求明細の作成
     * Param agreement 契約
     * Param billed 請求
     */
    public static BilledDetail__c createBilledDetail(Agreement__c agreement , PaymentDetails__c paymentDetail){
        system.debug(agreement.ID);

        //請求入金明細の作成
        BilledDetail__c billedDetail = new BilledDetail__c();
        if (agreement.rel_PaymentDetails__r.size() > 0) {
            //リース回数
            billedDetail.Count__c=paymentDetail.Count__c;
            //契約
            billedDetail.Agreement__c=agreement.ID;

            //月額リース料
            billedDetail.MonthlyLeaseFee__c = paymentDetail.Count__c==1 ? agreement.shokaileasefee__c :agreement.MonthlyLeaseFeeTotal2__c;

            //消費税(リース料)
            billedDetail.LeaseFeeTax__c = paymentDetail.Count__c==1 ? agreement.SyokaiLeaseTax__c :agreement.MonthlyLeaseFeeTax__c;

            //請求期間(開始)(リ)
            billedDetail.BilledKikanStart__c =paymentDetail.BilledKikanStart__c;

            //請求対象期間(終了)(リ)
            billedDetail.ReturnBilledKikanEnd__c =paymentDetail.ReturnBilledKikanEnd__c;

            //搬出入費等(リ) 初回以外の場合：0
            //billedDetail.HansyutuAmount__c=paymentDetail.Count__c==1 ?agreement.CostSum2__c :0 ;
            billedDetail.HansyutuAmount__c=paymentDetail.Count__c==1 ?agreement.CostSum3__c :0 ;

            //搬出入費等消費税(リ) 初回以外の場合：0
            billedDetail.HansyutuTax__c= paymentDetail.Count__c==1 ?agreement.CostTotalTax__c :0 ;

            //保証金 初回以外の場合：0
            billedDetail.Hoshokin__c = paymentDetail.Count__c==1 ?agreement.hoshokin__c :0 ;
			
			//合計金額(リ)
			billedDetail.TotalLeaseAmount2__c = paymentDetail.Payment__c;

            //摘要(リ) 使用者 + 物件名・部屋番号
            billedDetail.Wording__c = (agreement.UserNew__c==null?'':agreement.UserNew__c) + '<br/>' + (agreement.PropertyHomeNo__c==null ?'':agreement.PropertyHomeNo__c)  ;
        }

        return billedDetail;
    }
    
	public static List<Agreement__c> getAgreementList(String queryCondition, String querySubCondition , String KBN){
        //契約から検索(初回契約)
        String query='';
        query += ' SELECT ID,Name';
        query += '     ,Estimate__r.Seikyusaki__r.Id       ';//請求先
        query += '     ,Estimate__r.Seikyusaki__r.Name    ';//請求先名
        query += '     ,Estimate__r.Seikyusaki__r.Transfer_date__c    ';//振込期日（日）
        query += '     ,Estimate__r.KobetuBilledReqFlag__c  ';      //個別請求
        query += '     ,Estimate__r.RecordType.Name  ';      //RecordType
        query += '     ,Estimate__r.SeikyusakiAddress__c  ';      //請求先
        query += '     ,Estimate__r.SeikyusakiSendAddress__c  ';  //送付先
        query += '     ,Estimate__r.Seikyusaki__r.Account_number__c  ';      //請求先顧客番号
        query += '     ,Estimate__r.SeikyushoSend__r.Account_number__c  ';  //請求書送付先顧客番号
        query += '     ,FirstPaymentDate__c';      //初回支払期日
        query += '     ,MonthlyLeaseFeeTotal2__c           ';        //月額リース料（合計）
        query += '     ,MonthlyLeaseFeeTax__c         ';            //月額リース料（消費税）
        query += '     ,CostSum2__c          ';                      //諸費用総額(集計)
        query += '     ,CostSum3__c          ';                      //諸費用総額(集計、値引き含む)
        query += '     ,CostTotalTax__c   ';                        //諸費用総額消費税
        query += '     ,hoshokin__c       ';                        //保証金
        query += '     ,UserNew__c      ';                          //使用者
        query += '     ,PropertyHomeNo__c      ';                   //物件名・部屋番号
        query += '     ,shokaileasefee__c      ';					//(非表示)初回リース料金
        query += '     ,SyokaiLeaseTax__c      ';					//(非表示)初回リース料金消費税
        query += '     ,ReturnHoshokinDate__c      ';			    //返金日
        
        query += '     ,damageMoney__c      ';					    //(保証金返金)ダメージ料金
        query += '     ,DeliveryFee__c      ';					    //(保証金返金)個別送料
        query += '     ,OthersFee__c      ';					    //(保証金返金)その他料金
		query += '     ,TotalFee__c      ';					        //(保証金返金)差引
		query += '     ,ProductKaitoriTax__c      ';			    //買取商品金額(集計)


 		query += '     , (SELECT ID  ';
 		query += '     , UnitPriceLease__c  ';					//計算価値価格
 		query += '     , UnitPriceSellForLease__c  ';		    //販売価格(リース) 
 		query += '     , ProductFlag__c  ';		                //商品フラグ 
 		query += '                  FROM InventoryOpportunityProduct__r ' ;   //在庫案件商品
 		if (KBN == '保証金') {
 		    query += '       WHERE Status__c = \'買取\' ';
 		}
        query += '                  )';     
        
        
        query += '     , (SELECT ID,';
        query += '               KijitsuDate__c,      ';            //支払期日
        query += '               Count__c ,               ';        //回数
        query += '               Payment__c,               ';		//支払金額
        query += '               BilledKikanStart__c,    ';         //請求対象期間(開始)(リ)
        query += '               ReturnBilledKikanEnd__c ';         //請求対象期間(終了)(リ)
        query += '                  FROM rel_PaymentDetails__r ';   //支払予定明細
        query += '                  Where BilledDetail__c=null';    //請求明細
        query += querySubCondition;
        query += '                  ORDER BY KijitsuDate__c )';     //支払期日
        query += ' FROM Agreement__c ';                             //更新
        query += ' WHERE  ';
        query += queryCondition;
 		if (KBN != '保証金') {
 			query += ' AND (Status__c = \'契約済\' OR Status__c = \'契約待ち\')';
 		}
 		        
        query += ' ORDER BY Estimate__r.Seikyusaki__r.Id, Estimate__r.KobetuBilledReqFlag__c';
        system.debug(query);
        return Database.query(query);
    }
}