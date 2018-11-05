/** 
 * 更新トリガのハンドル
 */
public class AgreementTriggerHandler {
    
    /** 
     * 1.契約更新の場合、作成した後、元契約下の在庫案件商品をコピー作成して、新契約と紐づけます。
     * 2.在庫品を新契約と紐づけます。
     */ 
    public void AfterInsert(List<Agreement__c> newAgreementList) {
        for (Agreement__c agreement : newAgreementList) {
            //元契約の更新：元契約の子契約に新契約と関連する。
            Agreement__c oldAgreement = new Agreement__c(Id=agreement.ParentAgreement__c);
            oldAgreement.ChildAgreement__c = agreement.Id;
            update oldAgreement;
            
            //元契約のIDより、関連する在庫案件商品(リース中商品だけ)を全部取得する。
            List<InventoryOpportunityProduct__c> invOppProducts = getInvOppListByAgreementId(agreement.ParentAgreement__c);
            
            //在库案件商品をコピー作成して、新契約と紐づけます。
            List<InventoryOpportunityProduct__c> invOppProNewList = new List<InventoryOpportunityProduct__c>();
            //在庫の更新：新契約と紐づける。
            List<InventoryProduct__c> updateZaikoList = new List<InventoryProduct__c>();
            system.debug('invOppProducts');
            system.debug(invOppProducts);
            for(InventoryOpportunityProduct__c invOppProduct : invOppProducts){
            	//在庫の更新
                InventoryProduct__c invProduct = new InventoryProduct__c();
                invProduct.Id = invOppProduct.InventoryProduct__c;    //在庫ID
            	if (invOppProduct.Status__c == 'リース中') {//リース中の場合、在庫案件商品をコピー作成、且　在庫は新契約と紐づける。
            		//在庫案件商品をコピー作成
            	    InventoryOpportunityProduct__c invOppProNew = invOppProduct.clone(false, false, false, false);
                    invOppProNew.Agreement__c = agreement.Id;
                    invOppProNew.UpdateCnt__c = agreement.UpdateCnt__c;
                    invOppProNew.Haisou__c = null;
                    invOppProNew.ContractEndSellingRate__c = 0;
                	invOppProNew.MonthlyLeaseRateForUpd1__c = 0;
                	invOppProNew.MonthlyLeaseRateForUpd2__c = 0;
                	invOppProNew.MonthlyLeaseRateForUpd__c = 0;
                	invOppProNew.MonthlyLeaseRate__c = agreement.MonthlyLeaseRate__c;
                    invOppProNewList.add(invOppProNew);
                    
                    //在庫
                    invProduct.Agreement__c = agreement.Id;    //契約
            	} else if (invOppProduct.Status__c == '買取') {//買取の場合、在庫の現状区分と現状補助区分を更新する
            	    invProduct.CurrentStatus__c = '除却';
                    invProduct.CurrentStatusAuxiliary__c = '販売済';
            	} else if (invOppProduct.Status__c == '解約') {//削除の場合、在庫の現状補助区分を更新する
            	    invProduct.CurrentStatusAuxiliary__c = '返却予定';
            	}
            	updateZaikoList.add(invProduct);
            }
            insert invOppProNewList;
            
            update updateZaikoList;
            system.debug(updateZaikoList);
            
            //支払予定明細の作成
            paymentDetailsCreate(PdfGeneratorController.getAgreementById(agreement.Id));
            //支払予定表且覚書を作成
            paymentPDFCreate(agreement.Id,agreement.ParentAgreement__c);
        }
    }
    
   /** 
     * 支払予定表且覚書を作成
     * paymentLinkedId 支払予定表と紐づくエンティティID
     * aggrementId 更新ID
     * parentAgreementId 元契約のID
     * 仕組み：バッチ処理
     */
    @future (callout=true)
    public static void paymentPDFCreate(Id aggrementId , Id parentAgreementId) {
    	//覚書
        PdfGeneratorController.savePDFCommon(aggrementId, 'Oboegaki' , parentAgreementId);
        //支払予定表
        PdfGeneratorController.savePDFCommon(aggrementId, 'Shiharai',parentAgreementId);
    }
    
    /** 
     * 更新IDより、在庫案件商品を取得する
     */ 
    private List<InventoryOpportunityProduct__c> getInvOppListByAgreementId(String agreementId) {
        String soql2 = 'SELECT Id, Name '; 
        soql2 +=   ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('InventoryOpportunityProduct__c'), ',');
        soql2 +=   '   FROM InventoryOpportunityProduct__r WHERE SetupFeeFlag__c = FALSE AND KENSpecialDiscountFlag__c = FALSE AND DiscountFlag__c = FALSE )';
        soql2 +=   ' FROM Agreement__c WHERE Id = :agreementId';
        System.debug( 'getOppListByAgreementId: [' + soql2 + ']');
        Agreement__c agreement = Database.query(soql2);
        return agreement.InventoryOpportunityProduct__r;
    }
    
    /** 
     * 1.更新の更新承認申請を承認した後、新規更新の作成。
     * 2.商品は新更新と紐づけます。
     */ 
    public void AfterUpdate(List<Agreement__c> newAgreementList , List<Agreement__c> oldAgreementList) {
        //ループ処理に計数用
        Integer countNo = 0;
        //更新対象IDリスト
        List<Id> agreementIds = new List<Id>();
        //解約 或は 買取対象IDリスト
        List<Id> deleteAgreementIds = new List<Id>();
        //IDの確定
        for (Agreement__c agreement : newAgreementList) {
            system.debug(agreement.Status__c);
            system.debug(oldAgreementList[countNo].Status__c);
            if (agreement.Status__c == '契約更新済' && oldAgreementList[countNo].Status__c == '契約更新手続き中'
                    && (agreement.NextProductUpdCnt__c > 0)) {
                agreementIds.add(agreement.Id);
            } else if (agreement.Status__c == '契約解除待ち' && oldAgreementList[countNo].Status__c == '契約更新手続き中'
                    && (agreement.NextProductUpdCnt__c == 0)) {
                deleteAgreementIds.add(agreement.Id);
            }
            countNo++;
        }
        
        system.debug(deleteAgreementIds);
        system.debug(agreementIds);
        
        //更新対象がある場合、処理を行う
        if (agreementIds.size() > 0) {
            String soql = 'SELECT Id,LeaseMonth__c, ' + String.join(CommonUntil.getCopiableFieldNames('Agreement__c'), ',')
                + ',(SELECT Id,' + String.join(CommonUntil.getCopiableFieldNames('OpportunityProduct__c'), ',')
                + ' FROM Product__r) FROM Agreement__c WHERE Id in :agreementIds';
            
            List<Agreement__c> agreements = Database.query(soql);
            //新規更新リスト
            List<Agreement__c> newAgreements = new List<Agreement__c>();

            //更新リストを繰り返して、新更新を作成
            for (Agreement__c agreement : agreements) {
            	//複数の契約を作成する
            	//一回目
            	/*if(agreement.LeaseDateFirstEnd__c!=null){
            		Agreement__c agreementNew = agreement.clone(false, false, false, false);    //更新をコピー作成
            		agreementNew=createAgreement(agreementNew,agreement,1);
	                
	                agreementNew.LeaseEnd__c=agreement.LeaseEnd__c;//リース開始日(一回目)
	                agreementNew.LeaseDateFirstEnd__c=agreement.LeaseDateFirstEnd__c;//リース終了日(一回目)
            		newAgreements.add(agreementNew);
            		//二回目
            		if(agreement.LeaseDateSecendEnd__c!=null){
            			Agreement__c agreementNewChild = agreement.clone(false, false, false, false);    //更新をコピー作成
            			agreementNewChild=createAgreement(agreementNewChild,agreement,2);
		                
		                agreementNewChild.LeaseDateSecendStart__c=agreement.LeaseDateSecendStart__c;//リース開始日(二回目)
		                agreementNewChild.LeaseDateSecendEnd__c=agreement.LeaseDateSecendEnd__c;//リース終了日(二回目)
	            		newAgreements.add(agreementNewChild);
	            		//三回目
            			if(agreement.LeaseDateThirdEnd__c!=null){
            				Agreement__c agreementNewGChild = agreement.clone(false, false, false, false);    //更新をコピー作成
            				agreementNewGChild=createAgreement(agreementNewGChild,agreement,3);
			                
			                agreementNewGChild.LeaseDateSecendStart__c=agreement.LeaseDateSecendStart__c;//リース開始日(二回目)
			                agreementNewGChild.LeaseDateSecendEnd__c=agreement.LeaseDateSecendEnd__c;//リース終了日(二回目)
		            		newAgreements.add(agreementNewGChild);
            			}
            		}
            	
            	}else{*/
	                Agreement__c agreementNew = agreement.clone(false, false, false, false);    //更新をコピー作成
					agreementNew=createAgreement(agreementNew,agreement,1);
	                newAgreements.add(agreementNew);
            	//}
            }
            system.debug(newAgreements);
            insert newAgreements;
            //元契約と子契約の更新
            /*if(newAgreements.size()>1){
            	//一回目の契約を当契約に更新
            	agreements[0].ChildAgreement__c=newAgreements[0].id;
            	if(newAgreements.size()>=2){
            		newAgreements[1].ParentAgreement__c=newAgreements[0].id;
            		newAgreements[0].ChildAgreement__c=newAgreements[1].id;
            		if(newAgreements.size()==3){
            			newAgreements[2].ParentAgreement__c=newAgreements[1].id;
            			newAgreements[1].ChildAgreement__c=newAgreements[2].id;
            			newAgreements[2].ChildAgreement__c=null;
            		}
            	}
            	
            	system.debug(newAgreements);
            	system.debug(agreements);
            	update newAgreements;
            	update agreements;
            }*/
           
            //新更新を作成後、在庫と商品を新更新と紐づけます。
            AfterInsert(newAgreements);
        }
        
        //買取、解約更新対象がある場合、処理を行う
        if (deleteAgreementIds.size() > 0) {
        	//在庫の更新：新契約と紐づける。
            List<InventoryProduct__c> updateZaikoList = new List<InventoryProduct__c>();
            //更新リストを繰り返して、新更新を作成
            for (Id id : deleteAgreementIds) {
                //元契約のIDより、関連する在庫案件商品(リース中商品だけ)を全部取得する。
                List<InventoryOpportunityProduct__c> invOppProducts = getInvOppListByAgreementId(id);
                for(InventoryOpportunityProduct__c invOppProduct : invOppProducts){
            	    //在庫の更新
                    InventoryProduct__c invProduct = new InventoryProduct__c();
                    invProduct.Id = invOppProduct.InventoryProduct__c;    //在庫ID
            	    if (invOppProduct.Status__c == '買取') {//買取の場合、在庫の現状区分と現状補助区分を更新する
            	        invProduct.CurrentStatus__c = '除却';
                        invProduct.CurrentStatusAuxiliary__c = '販売済';
            	    } else if (invOppProduct.Status__c == '解約') {//削除の場合、在庫の現状補助区分を更新する
            	        invProduct.CurrentStatusAuxiliary__c = '返却予定';
            	    }
            	    updateZaikoList.add(invProduct);
                }
            }
            update updateZaikoList;
        }
    }
    
    /** 
     * 契約作成
     * agreement 契約オブジェクト
     */
    public static Agreement__c createAgreement(Agreement__c agreementNew,Agreement__c agreement,Integer add) {
	    
		agreementNew.Name = agreement.Name.left(6) + String.valueOf(Integer.valueOf(agreement.Name.right(3)) + add).leftPad(3, '0');    //更新の問い合わせ番号
        agreementNew.LeaseStart__c = agreement.NextLeaseStartHope__c;    //(次)リース開始希望日を新契約のリース開始日にセットする。
        agreementNew.LeaseEnd__c = agreement.NextLeaseEndHope__c;        //(次)リース終了希望日を新契約のリース終了日にセットする。
        agreementNew.NextLeaseStartHope__c = null;                       //(次)リース開始希望日をリセットする。
        agreementNew.NextLeaseEndHope__c = null;                        //(次)リース終了希望日をリセットする。
        agreementNew.ContractEndSellingRate__c = 0;
        agreementNew.MonthlyLeaseRateForUpd__c = 0;
        agreementNew.ParentAgreement__c = agreement.Id;
        agreementNew.LeaseTermEndFlg__c = false;
        agreementNew.Status__c = '契約済';                         //ステータス
        agreementNew.ApprovalStatus__c = '未提出';                 //承認状態
        agreementNew.UpdateCnt__c = agreement.UpdateCnt__c + 1;    //更新回数
        agreementNew.KaiyakuDate__c = null;                        //解約日
        agreementNew.AgreementUpdateDate__c = null;                //更新日
        agreementNew.HoshokinComment__c = null;                    //保証金返金申請コメント
        agreementNew.updateAgreementComment__c = null;             //更新コメント
        agreementNew.MonthlyLeaseRate__c = agreement.MonthlyLeaseRateForUpd__c	; //月額リース料率
        return agreementNew;
    }
    
    /** 
     * 支払予定明細作成
     * agreement 契約オブジェクト
     */
    public static void paymentDetailsCreate(Agreement__c agreement) {
        system.debug('支払予定明細作成開始');
        system.debug(agreement);
        //既に支払予定明細を作成したの場合、既存の明細を削除する。
        if (agreement.rel_PaymentDetails__r.size() > 0) {
            delete agreement.rel_PaymentDetails__r;
        }
        
        if ((Integer)agreement.PaymentCount__c > 0) {
            //初回支付残高、金额
            Decimal balanceFee;
            Decimal shokaileasefee;
            //月額リース料(税込み)
            Decimal monthFee= agreement.MonthlyLeaseFeeTotal2__c + agreement.MonthlyLeaseFeeTax__c;
            
            if (agreement.UpdateCnt__c == 0) {
                if ( agreement.TotalAcceptanceUponContract__c != null) {
            	    shokaileasefee = agreement.TotalAcceptanceUponContract__c;
                    //balanceFee = agreement.PaymentAmountWithTaxSum__c - shokaileasefee;
                    balanceFee = agreement.Estimate__r.PayAmountWithTax__c - shokaileasefee;
                } else {
                    //balanceFee = agreement.PaymentAmountWithTaxSum__c - 0;
                    balanceFee = agreement.Estimate__r.PayAmountWithTax__c - 0;
                    shokaileasefee = 0;
                }
            } else {
	            shokaileasefee = agreement.shokaileasefee__c + agreement.SyokaiLeaseTax__c;
	            balanceFee = agreement.PaymentAmountWithTaxSum__c - shokaileasefee;
	            //balanceFee = agreement.Estimate__r.PayAmountWithTax__c - shokaileasefee;
            }
            
            List<PaymentDetails__c> PaymentDetails = new List<PaymentDetails__c>();
            PaymentDetails__c pd = new PaymentDetails__c(Estimate__c = agreement.Estimate__c,
                                                         Count__c = 1,
                                                         Agreement__c = agreement.Id,
                                                         KijitsuDate__c = agreement.FirstPaymentDate__c,
                                                         Payment__c = shokaileasefee,
                                                         BilledKikanStart__c = agreement.LeaseStart__c,
                                                         PaymentBalance__c = balanceFee
                                                        );
            PaymentDetails.add(pd);
            //二回目の支払期日を算出
            Date secondPaymentDate = system.today();
            
            //初回支払期日末日
            Date firstPaymentDateEnd = system.today();
            if (agreement.UpdateCnt__c == 0) {
                firstPaymentDateEnd = agreement.Estimate__r.FirstKikanTo1__c;
                if (agreement.Estimate__r.Opportunity__r.Account.PaymentMethod__c == 'クレジットカード') { //カード支払いの場合
                    if (agreement.Estimate__r.Opportunity__r.Account.Card_date__c != null) {
                        secondPaymentDate = Date.newInstance(firstPaymentDateEnd.year(),firstPaymentDateEnd.month() , (Integer)agreement.Estimate__r.Opportunity__r.Account.Card_date__c);
                    } else {
                        secondPaymentDate = Date.newInstance(firstPaymentDateEnd.year(),firstPaymentDateEnd.month() , 1);
                    }
                } else {//振込の場合
                    if (agreement.Estimate__r.Opportunity__r.Account.Transfer_date__c != null) {
                        	secondPaymentDate = Date.newInstance(firstPaymentDateEnd.year(),firstPaymentDateEnd.month() , (Integer)agreement.Estimate__r.Opportunity__r.Account.Transfer_date__c);
                    } else {
                        secondPaymentDate = Date.newInstance(firstPaymentDateEnd.year(),firstPaymentDateEnd.month() , 1);
                    }
                }
            } else {
                secondPaymentDate = (agreement.FirstPaymentDate__c).addMonths(1);
            }

            //二回目の請求期間開始日
            Date secondBilledKikanStart = Date.newInstance(secondPaymentDate.year(),secondPaymentDate.month() + 1, 1);
            for (integer j = 2; j <= (Integer)agreement.PaymentCount__c; j++){
                PaymentDetails__c pd1 = new PaymentDetails__c(Estimate__c = agreement.Estimate__c,
                                                              Agreement__c = agreement.Id,
                                                              BilledKikanStart__c = secondBilledKikanStart.addMonths(j-2),
                                                              Count__c = j,KijitsuDate__c = secondPaymentDate.addMonths(j-2));
                                                              
                if( (Integer)agreement.PaymentCount__c != j){
                    balanceFee = balanceFee - monthFee;
                    pd1.Payment__c = monthFee;
                    pd1.PaymentBalance__c = balanceFee;
                } else{
                    pd1.Payment__c = balanceFee;
                    pd1.PaymentBalance__c = 0;
                }
                PaymentDetails.add(pd1);
            }
            insert PaymentDetails;
        }
        system.debug('支払予定明細作成終了');
    }
}