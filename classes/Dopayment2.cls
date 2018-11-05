public class Dopayment2 {

	//請求先単位で、入金レコードリスト
	private Static Map<ID, List<Payment__c>> paymentAccountMap = new Map<Id, List<Payment__c>>();	

	//請求先単位で、請求明細レコードリスト
	private Static Map<ID, List<BilledDetail__c>> billedDetailMap = new Map<ID, List<BilledDetail__c>>();

     /**
     * 入金消込処理
     */	
	public static void executeKesikomi(){
		//消込処理していない入金レコードを取得
		getPaymentList();
		if(paymentAccountMap.size() == 0){
			system.debug('入金レコードがありません、処理終了');
			return;
		}
		//入金の請求先を対象で、すべての請求明細を抽出
		getBilledDetail();
		//１件ずつの入金データに対して、請求明細の消込を行う
		kesikomiBilledDetailByPayment();
		//預り金から、請求明細の消込を行う
		kesikomiBilledDetailByAzukarikin();
	}

     /**
     * 消込処理していない入金レコードを取得
     */	
	private static void getPaymentList(){

		String query = '';

		query += ' SELECT   ';
        query += '  Id, Account__c '; 							//請求先
        query += '  ,PaymentAmountInput__c '; 					//入金金額
        query += '  FROM Payment__c';   						//入金
        query += '  WHERE KeshikomiFinishiFlag__c = False ';	//消込済フラグ 
        query += '  Order BY Account__c ' ;						//請求先
        query += '           ,PaymentDate__c ' ;				//入金日

        //system.debug('getPaymentList:' + query);

        List<Payment__c> paymentList = Database.query(query);
        //system.debug('getPaymentList paymentList:' + paymentList.size());
        
        List<Payment__c> eachAccountPaymentList = new List<Payment__c>();
        ID accountTmpId;

        //請求先単位で、入金レコードリスト
        for(Payment__c payment : paymentList){
        	//消込済フラグ をセット
        	payment.KeshikomiFinishiFlag__c = true;
        	
        	if(accountTmpId == null || accountTmpId != payment.Account__c){
        		accountTmpId = payment.Account__c;
        		eachAccountPaymentList = new List<Payment__c>();

        		//請求先単位で、入金レコードリスト
        		paymentAccountMap.put(accountTmpId, eachAccountPaymentList);
         	}
        	eachAccountPaymentList.add(payment);
        }	

        //system.debug('getPaymentList paymentAccountMap:' + paymentAccountMap);
        
        //消込済フラグ を更新
        if(paymentList.size() > 0){
        	update paymentList;
        }		
	}

     /**
     * 入金の請求先を対象で、すべての請求明細を抽出
     */	
	private static void getBilledDetail(){
        List<BilledDetail__c> billedDetailList = [
		 SELECT   
          ID,NAME  														//請求明細No
          ,Billed__r.Account__c  										//請求先
          ,BilledAmount__c 												//請求金額
          ,Payment__c													//入金
          ,PaymentAmount__c												//入金金額
          ,PaymentDate__c												//入金日
          ,AzukariNyukinDate__c											//請求明細.預り金入金日
          FROM BilledDetail__c   										//請求明細
          WHERE Billed__r.Account__c in: paymentAccountMap.keyset()	    //請求先
          AND Sagaku__c <> 0 											//差額
          Order BY Billed__r.Account__c 								//請求先
          , Billed__r.BilledDate__c 									//請求日        
        ];

        system.debug('getBilledDetail billedDetailList:' + billedDetailList.size());

        List<BilledDetail__c> eachAccountBilledDetailList = new List<BilledDetail__c>();
        ID accountTmpId;

        //請求先単位で、入金レコードリスト
        for(BilledDetail__c bd : billedDetailList){
        	if(accountTmpId == null || accountTmpId != bd.Billed__r.Account__c){
        		accountTmpId = bd.Billed__r.Account__c;
        		eachAccountBilledDetailList = new List<BilledDetail__c>();

        		//請求先単位で、請求明細レコードリスト
        		billedDetailMap.put(accountTmpId, eachAccountBilledDetailList);
         	}
        	eachAccountBilledDetailList.add(bd);
        }	

        system.debug('getBilledDetail billedDetailMap:' + billedDetailMap);
	}

     /**
     * １件ずつの入金データに対して、請求明細の消込を行う
     */	
	private static void kesikomiBilledDetailByPayment(){
		//入金マップ
		for(ID accountId: paymentAccountMap.keyset()){
			//入金データの消込
			kesikomiBilledDetail(accountId, paymentAccountMap.get(accountId));
		}	
	}
	
     /**
     * 入金データの消込
     */		
	private static void kesikomiBilledDetail(ID accountId, List<Payment__c> paymentList){

		//請求明細リスト
		List<BilledDetail__c> billedDetailList = billedDetailMap.get(accountId);

		//請求明細更新リスト
		List<BilledDetail__c> updBilledDetailList = new List<BilledDetail__c>();
		
		//預り金リスト
		List<AzukariDetail__c> azukariDetailList = new List<AzukariDetail__c>();
		
		//入金レコードをループ
		for(Payment__c payment: paymentList){
			//入金レコードからの入金金額
			decimal pAmoount = payment.PaymentAmountInput__c ;
			system.debug('kesikomiBilledDetail 消込前 pAmoount:' + pAmoount);
			
            if (billedDetailList != null && !billedDetailList.isEmpty()) {
                for(BilledDetail__c bd : billedDetailList){
				    //請求金額
				    decimal bdAmoount = bd.BilledAmount__c;
				    system.debug('kesikomiBilledDetail bdAmoount:' + bdAmoount);
				
				    //system.debug('kesikomiBilledDetail bd.PaymentAmount__c:' + bd.PaymentAmount__c);
				    //請求明細.入金金額が0
				    if(bd.PaymentAmount__c == null || bd.PaymentAmount__c == 0){
					    //入金レコードからの入金金額 >= 請求金額
					    if(pAmoount >= bdAmoount){
						    pAmoount = pAmoount- bdAmoount;					//入金レコードからの入金金額				

						    bd.Payment__c = payment.Id;						//請求明細.入金
						    bd.PaymentAmount__c	= bdAmoount;				//請求明細.請求金額
						    updBilledDetailList.add(bd);
						
					    }else{
						    //入金レコードからの入金金額 < 請求金額
						    break;
					    }
				    }
                }
			} 
			
			//system.debug('kesikomiBilledDetail 消込後 pAmoount:' + pAmoount);
			
			//入金レコードからの入金金額 はあまりがある場合
			if(pAmoount > 0){
				//預り金レコードを作成する
				AzukariDetail__c ad = new AzukariDetail__c();
				//請求先
				ad.Account__c = accountId;
				//入金
				ad.Payment__c = payment.Id;
				//金額
				ad.Amount__c = pAmoount;
				azukariDetailList.add(ad);	
			}
		}
		//system.debug('kesikomiBilledDetail updBilledDetailList:' + updBilledDetailList.size());
		//system.debug('kesikomiBilledDetail azukariDetailList' + azukariDetailList.size());
		
		//消込済みの請求レコードをUpdate
		if(updBilledDetailList.size() > 0){
			update updBilledDetailList;
		}		

		//預り金リスト
		if(azukariDetailList.size() > 0){
			//system.debug('kesikomiBilledDetail azukariDetailList' + azukariDetailList);
			insert azukariDetailList;
		}	
	}


     /**
     * 預り金から、請求明細の消込を行う
     */	
	private static void kesikomiBilledDetailByAzukarikin(){

		//入金の請求先を対象で、すべての請求明細を抽出
		getBilledDetail();
		
		//入金の請求先を対象で、請求先の預り金を取得
		Map<Id, decimal> accAzukariAmountMap = getAccountAzukariAmount();
		//system.debug('kesikomiBilledDetailByAzukarikin accAzukariAmountMap' + accAzukariAmountMap);
		
		//すべての請求先の預り金がない場合、処理中止
		if(accAzukariAmountMap.size() == 0){
			return;
		}
		
		//請求明細更新リスト
		List<BilledDetail__c> updBilledDetailList = new List<BilledDetail__c>();
		
		//預り金リスト
		List<AzukariDetail__c> azukariDetailList = new List<AzukariDetail__c>();
		
		//入金レコードをループ
		for(Id accountId: billedDetailMap.keySet()){
			//預り金を取得
			decimal azukariAmoount = accAzukariAmountMap.get(accountId) ;
			//請求先の預り金がない場合、continue
			if(azukariAmoount == 0){
				continue;
			}
			
			List<BilledDetail__c> billedDetailList = billedDetailMap.get(accountId);
			
			for(BilledDetail__c bd : billedDetailList){
				//請求金額
				decimal bdAmoount = bd.BilledAmount__c;
				//system.debug('kesikomiBilledDetailByAzukarikin 預り金額 azukariAmoount' + azukariAmoount);
				//system.debug('kesikomiBilledDetailByAzukarikin 請求金額 bdAmoount' + bdAmoount);
				//system.debug('kesikomiBilledDetailByAzukarikin 入金金額 bd.PaymentAmount__c' + bd.PaymentAmount__c);

				//請求明細.入金金額がない場合
				if(bd.PaymentAmount__c == null || bd.PaymentAmount__c == 0){
					//system.debug('kesikomiBilledDetailByAzukarikin 1');
					//預り金 >= 請求金額
					if(azukariAmoount >= bdAmoount){
						//system.debug('kesikomiBilledDetailByAzukarikin 2');
						azukariAmoount = azukariAmoount- bdAmoount;		//預り金				
						
						//請求明細
						bd.AzukariNyukinDate__c = System.today();			//請求明細.預り金入金日
						bd.PaymentAmount__c	= bdAmoount;					//請求明細.入金金額
						updBilledDetailList.add(bd);
						
						//預り金レコードを作成する
						AzukariDetail__c ad = new AzukariDetail__c();
						//請求先
						ad.Account__c = accountId;
						//請求明細
						ad.BilledDetail__c = bd.Id;
						//金額
						ad.Amount__c = bdAmoount * -1;
						azukariDetailList.add(ad);	
					}else{
						break;
					}
				}											
			} 					
		}	
			
		//system.debug('kesikomiBilledDetailByAzukarikin updBilledDetailList:' + updBilledDetailList.size());
		//system.debug('kesikomiBilledDetailByAzukarikin azukariDetailList' + azukariDetailList.size());
		
		//消込済みの請求レコードをUpdate
		if(updBilledDetailList.size() > 0){
			update updBilledDetailList;
		}		

		if(azukariDetailList.size() > 0){
			insert azukariDetailList;
		}
	}
	
	/**
     * 入金の請求先を対象で、請求先の預り金を取得
     */	
	private static Map<Id, decimal> getAccountAzukariAmount(){
        List<Account> accountList = [ SELECT  
          								Id, AzukariAmount__c  					//預り金(集計)
          								FROM Account   							//取引先
          								WHERE Id in: paymentAccountMap.keyset() //請求先
          								Order BY Id								//請求先
        							];
        ID accountTmpId;
        
        Map<Id, decimal> accAzukariAmountMap =  new  Map<Id, decimal>();

        //請求先単位で、入金レコードリスト
        for(Account acc : accountList){
        	//請求先単位で、入金レコードリスト
        	accAzukariAmountMap.put(acc.Id, acc.AzukariAmount__c);
        }	
        return accAzukariAmountMap;	
	}
	
}