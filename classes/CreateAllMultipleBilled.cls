public with sharing class CreateAllMultipleBilled extends CreateInvoiceFatherBilled{
    /**
     * 一括請求 
     * Param year 請求年
     * Param month 請求月
     * Param PaywayValue 支払い方法
     * Param localValue 請求先と送付先住所
	 * Param day 期日(日)
	 * Param request 取引先
	 * Param questionNO 契約問い合わせ番号
     */  
    @AuraEnabled
    public static void createAllBilled(String year,String month,String PaywayValue,String localValue,String day,String request,String questionNO){
    	//検索条件
    	String queryCondition='';
    	String querySubCondition='';

	    Date billedDateEnd = Date.newInstance(Integer.valueOf(year),Integer.valueOf(month),1);
	    billedDateEnd = billedDateEnd.addMonths(1).addDays(-1);

	    //支払予定明細、支払い期日
        querySubCondition = ' AND KijitsuDate__c <= ' + String.valueOf(billedDateEnd);
        //リースのみ契約
    	queryCondition +=  ' Estimate__r.RecordType.Name = \'リース\'' ;
        system.debug(querySubCondition);
    	if(String.isBlank(request) && String.isBlank(questionNO)){//一括取引先
	    	if(String.isNotBlank(day)){
	    		//期日
	    	 	queryCondition +=  ' AND Estimate__r.Opportunity__r.Account.Transfer_date__c <='+ Double.valueOf(day);
	    	}
	    	if(String.isNotBlank(PaywayValue)){
	    		//支払い方法
	    	 	queryCondition +=  ' AND PaymentMethod__c =\''+ PaywayValue+ '\'' ;
	    	}
    	}else{//個別取引先
    		if(String.isNotBlank(request)){
    			//請求先
    	 		queryCondition +=  ' AND Estimate__r.Seikyusaki__c =\''+ request+ '\'' ;
	    	}
	    	if(String.isNotBlank(questionNO)){
	    		//問い合わせNO
	    	 	queryCondition +=  ' AND id =\''+ questionNO+ '\'' ;
	    	}
    	}
    	//月次請求纏めフラグ
    	//queryCondition +=  ' AND Estimate__r.MonthlyPrintFlag__c =true';
        system.debug('queryCondition::' + queryCondition);
        //CreateInvoiceFatherBilledをコールし、更新、支払予定明細データを取得
        List<Agreement__c> AgreementList = getAgreementList(queryCondition, querySubCondition,'');
		system.debug('AgreementList::' + AgreementList);
		//請求、請求明細を作成。
        createBilled(AgreementList,localValue,request,questionNO,Date.newInstance(Integer.valueOf(year),Integer.valueOf(month),1));
    }

    /**
     * 一括請求、請求明細作成 
     * @Kijitu  支払期日　　　
     * @AgreementList  更新
     */
    private static void createBilled(List<Agreement__c> AgreementList,String local,String request,String questionNO , Date BilledDate){
        //請求
        List<Billed__c> billedList=new List<Billed__c>();
        //請求明細
        List<BilledDetail__c> billedDetailList=new List<BilledDetail__c>();
        //支払予定明細
        List<PaymentDetails__c> paymentDetailList=new List<PaymentDetails__c>();
        //有効契約リスト
        List<Agreement__c> agreements = new List<Agreement__c>();
        //契約Id-契約オブジェクトMap
        Map<String,Agreement__c> agreementMap = New Map<String,Agreement__c>();
        //契約-請求Idx
        Map<String,Integer> agBilledMap = New Map<String,Integer>();

        //有効契約の絞り
        for(Agreement__c agreement:AgreementList){
        	system.debug(agreement.rel_PaymentDetails__r.size());
            if(agreement.rel_PaymentDetails__r.size() > 0){
                if(String.isBlank(request) && String.isBlank(questionNO)){//一括請求の場合
                    if(local=='一致する'){
                        if(agreement.Estimate__r.Seikyusaki__r.Account_number__c==agreement.Estimate__r.SeikyushoSend__r.Account_number__c){
                            agreements.add(agreement);
                        }
                    }else{
                        if(agreement.Estimate__r.Seikyusaki__r.Account_number__c!=agreement.Estimate__r.SeikyushoSend__r.Account_number__c){
                            agreements.add(agreement);
                        }
                    }
                } else {
                    agreements.add(agreement);
                }
            }
        }
        system.debug(agreements);
        //請求を作成
        String billedReqKey = '';
        for(Agreement__c agreement : agreements){
            //比較キー： 請求先ID + 合算請求フラグ
            String compareKey = agreement.Estimate__r.Seikyusaki__r.Id  + String.valueOf(agreement.Estimate__r.KobetuBilledReqFlag__c);
            paymentDetailList.addAll(agreement.rel_PaymentDetails__r);
            
            agreementMap.put(agreement.Id,agreement);
            if (compareKey != billedReqKey || agreement.Estimate__r.KobetuBilledReqFlag__c==false) {
                billedList.add(createBilled(agreement,BilledDate));
                agBilledMap.put(agreement.Id,billedList.size()-1);
            } else {
                agBilledMap.put(agreement.Id,billedList.size()-1);
            }
            system.debug(agBilledMap);
            //退避
            billedReqKey = compareKey;
        }
        insert billedList;
        system.debug(billedList);
        //請求明細データを作成する
        if (billedList.size() > 0) {
            for(Agreement__c agreement : agreements){
                billedDetailList.addAll(createDetailData(agreement,billedList[agBilledMap.get(agreement.Id)].Id));
            }
            insert billedDetailList;
            //支払予定明細は請求明細と紐づける
            Integer i = 0;
            for(PaymentDetails__c paymentDetail: paymentDetailList){
        	    paymentDetail.BilledDetail__c = billedDetailList[i].id;
        	    i++;
    	    }
    	    update paymentDetailList;
        }
    }
    
    /**
	　* 請求データを作成する
     */
    private static Billed__c createBilled(Agreement__c agreement, Date BilledDate){
        Billed__c billed = new Billed__c();
	    //請求先
	    billed.Account__c = agreement.Estimate__r.Seikyusaki__r.Id;
	    //区分
	    billed.Type__c = agreement.Estimate__r.RecordType.Name;
	    //請求日
	    billed.BilledDate__c = BilledDate;
	
	    return billed;
    }
    
	/**
	　* 請求明細データを作成する
     */    
    private static List<BilledDetail__c> createDetailData(Agreement__c agreement,String BilledId){
    	//請求明細
        List<BilledDetail__c> billedDetailList=new List<BilledDetail__c>();
        
        for(PaymentDetails__c paymentDetail: agreement.rel_PaymentDetails__r){
            //請求明細の作成
            BilledDetail__c billedDetail = new BilledDetail__c();
            //CreateInvoiceFatherBilledをコールし、明細を作成
            billedDetail = createBilledDetail(agreement,paymentDetail);
            billedDetail.Billed__c = BilledId;
            billedDetailList.add(billedDetail);
        }
        
        return billedDetailList;
    }
    
    /**
	　* 印刷するとき、一括請求明細データを取得
     */  
    @AuraEnabled
    public static List<Id> getAllBilledDetailIds(String year,String month,String PaywayValue,String localValue,String day,String request,String questionNO){
    	//検索条件
	    Date billedDateEnd = Date.newInstance(Integer.valueOf(year),Integer.valueOf(month),1);
	    
	    //SQLを作成
		String sqlQuery = 'SELECT Id,Name,Billed__r.Account__c,BilledAmount__c,Payment__c,PaymentAmount__c,PaymentDate__c,AzukariNyukinDate__c';
		sqlQuery += ' ,Agreement__r.Estimate__r.SeikyusakiAddress__c,Agreement__r.Estimate__r.SeikyusakiSendAddress__c';
		sqlQuery += ' FROM BilledDetail__c';
		sqlQuery += ' WHERE Sagaku__c <> 0 ';
		sqlQuery += ' AND (CreateBilledDate__c < ' + String.valueOf(billedDateEnd) +' OR CreateBilledDate__c=NULL)';
		sqlQuery += ' AND Agreement__r.Estimate__r.RecordType.Name = \'リース\'';
		if(String.isBlank(request) && String.isBlank(questionNO)){//一括取引先
	    	if(String.isNotBlank(day)){
	    		//期日
	    	 	sqlQuery +=  ' AND Billed__r.Account__r.Transfer_date__c <='+ Double.valueOf(day);
	    	}
	    	if(String.isNotBlank(PaywayValue)){
	    		//支払い方法
	    	 	sqlQuery +=  ' AND Agreement__r.PaymentMethod__c =\''+ PaywayValue+ '\'' ;
	    	}
    	}else{//個別取引先
    		if(String.isNotBlank(request)){
    			//請求先
    	 		sqlQuery +=  ' AND Billed__r.Account__c =\''+ request+ '\'' ;
	    	}
	    	if(String.isNotBlank(questionNO)){
	    		//問い合わせNO
	    	 	sqlQuery +=  ' AND Agreement__c =\''+ questionNO+ '\'' ;
	    	}
    	}
    	List<Id> billedDetailIdList = new List<Id>();
    	system.debug(sqlQuery);
    	List<BilledDetail__c> billedDetailList = Database.query(sqlQuery);
    	system.debug(billedDetailList);
    	for (BilledDetail__c BilledDetail : billedDetailList) {
    	    if(String.isBlank(request) && String.isBlank(questionNO)){//一括請求の場合
                if(localValue=='一致する'){
                    if(BilledDetail.Agreement__r.Estimate__r.SeikyusakiAddress__c == BilledDetail.Agreement__r.Estimate__r.SeikyusakiSendAddress__c){
                        billedDetailIdList.add(BilledDetail.Id);
                    }
                }else{
                    if(BilledDetail.Agreement__r.Estimate__r.SeikyusakiAddress__c != BilledDetail.Agreement__r.Estimate__r.SeikyusakiSendAddress__c){
                        billedDetailIdList.add(BilledDetail.Id);
                    }
                }
            } else {
                billedDetailIdList.add(BilledDetail.Id);
            }
    	}
    	return billedDetailIdList;
    }
}