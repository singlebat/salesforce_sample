public class Dopayment {
     /**
     * 請求明細を更新
     * Param payment 入金
     *入金No  入金金額
	 *ロジック整理
	 *               N                        M　　　　　　　　　　　　　S
	 *			複数の入金　　　　　       複数の請求              複数の請求明細
	 *				入金１　　　　　　　　　　請求１　　　　　　　　　　請求明細１
	 *				入金１　　　　　　　　　　請求１　　　　　　　　　　請求明細２
	 *				入金１　　　　　　　　　　請求２　　　　　　　　　　請求明細３
	 *　　　　　　　入金２　　　　　　　　　　請求３　　　　　　　　　　請求明細４
     */
    @AuraEnabled
    public static void dopayment(List<Payment__c> oldpaymentList){
        //入金の情報を取り直す
        List<AggregateResult> paymentList=searchpaymentList(oldpaymentList);

        List<List<BilledDetail__c>> billedDetailDoubleList = new List<List<BilledDetail__c>>();
        
        List<BilledDetail__c> newBilledDetailList = new List<BilledDetail__c>();
        
        //検索条件を準備する
        string condition='';
        for(AggregateResult payment:paymentList){
            condition=condition+'\''+(String)payment.get('Account__c')+'\',';
        }
        condition='AND Billed__r.Account__c in ('+condition.substring(0, condition.length()-1)+')';

        //すべての請求明細をゲット
        List<BilledDetail__c> billedDetailListAll=searchBilledDetail(condition);
        //すべての請求金額をゲット
        List<AggregateResult> sumNyukinnAll=getNyukinn(condition);
        
        
        
        //現在入金の請求明細
        List<BilledDetail__c> billedDetailList=null;
        //差額の集計
        Integer Sagaku =0;
        //預かり金の集計
        Integer azukarikin=0;
        //現在入金の請求毎の請求金額の集計
        List<AggregateResult> sumNyukinn=null;
        //入金毎にループ
        for(AggregateResult payment:paymentList){
            //現在入金の請求明細を取得
            billedDetailList=searchBilledDetail(billedDetailListAll,payment);
            //預かり金の集計
            azukarikin =getAzukari(billedDetailList);
            //差額の集計
            Sagaku =getSagaku(billedDetailList,payment);
            //現在入金の請求毎の請求金額の集計
            sumNyukinn=getNyukinn(sumNyukinnAll,payment);
            
            //入金金額
            Decimal nyukinn=(Decimal)payment.get('PaymentAmountHosei__c');

            for(BilledDetail__c bDetail:billedDetailList){
                //今回の請求金額
                Decimal temp =bDetail.TotalLeaseAmount2__c;
                //これまでの預かり金がある場合    
                if(azukarikin>0 && bDetail.AzukariAmount__c == true){
                    system.debug('107');
                    //bDetail.Billed__c=billedDetailList[billedDetailList.size()-1].Billed__c;//請求NO  
                    //入金は預かり金を足す
                    system.debug(bDetail.Sagaku__c);
                    Decimal sa=bDetail.Sagaku__c;
                    system.debug(nyukinn);
                    system.debug(nyukinn - sa);
                    if(sa != null){
                        nyukinn = nyukinn - sa;
                    }
                    Decimal sumrequest=0;
                    for(AggregateResult sumnyu: sumNyukinn){
                        if((String)sumnyu.get('Billed__c')==bDetail.Billed__c){
                            sumrequest=(Decimal)sumnyu.get('sumrequest');
                        }
                    }
                    system.debug(sumrequest);
                    //bDetail.Payment__c=payment.Id;//(検証)入金
                    //入金＜請求
                    if(nyukinn<=sumrequest){
                        bDetail.AzukariAmount__c=false;//預り金フラグ
                    }else{
                        bDetail.AzukariAmount__c=true;//預り金フラグ
                    }    
                }
                else{
                    if(nyukinn>0){
                        //差額が存在する場合、欠
                        if(Sagaku>0){
                            system.debug(nyukinn);
                            Sagaku=Sagaku-Integer.valueOf(nyukinn);
                            system.debug(Sagaku);
                            if( nyukinn>temp){
                                //入金＞請求金額の場合、普通なら補正する必要がありません
                                bDetail.PaymentAmount__c=temp;
                                system.debug( bDetail.PaymentAmount__c);
                                if(bDetail.PaymentAmountHosei__c!=null){
                                    nyukinn=nyukinn+bDetail.PaymentAmountHosei__c-temp;
                                }else{
                                    nyukinn=nyukinn-temp;
                                }
                                system.debug(nyukinn);
                            }else{
                                //入金
                                bDetail.PaymentAmount__c=nyukinn;
                                //補正金額
                                bDetail.HoseiAmount__c=(Decimal)payment.get('HoseiAmount__c');
                                system.debug(nyukinn);
                                nyukinn=0;
                            }
                        }else{
                            if( nyukinn>=temp){
                                bDetail.PaymentAmount__c=temp;
                                nyukinn-=temp;
                            }else{
                                //入金
                                bDetail.PaymentAmount__c=nyukinn;
                                //補正金額
                                bDetail.HoseiAmount__c=(Decimal)payment.get('HoseiAmount__c');
                                system.debug(nyukinn);
                                nyukinn=0;
                            }
                        }
                    }
                    bDetail.Payment__c=payment.Id;//(検証)入金
                    bDetail.AzukariAmount__c=false;//預り金フラグ
                    }
            }
            billedDetailDoubleList.add(billedDetailList);
            system.debug(billedDetailList);
            //預かり金が発生する場合
            system.debug(nyukinn);
            if(nyukinn>0 && billedDetailList!=null){ 
                BilledDetail__c newBilledDetail = new  BilledDetail__c();        
                newBilledDetail.Payment__c=payment.Id;//(検証)入金
                //newBilledDetail.PaymentNo__c=payment.Name;//入金No
                newBilledDetail.PaymentAmount__c=nyukinn;//入金金額
                newBilledDetail.Billed__c=billedDetailList[0].Billed__c;//請求NO
                newBilledDetail.Agreement__c=billedDetailList[0].Agreement__c;//契約NO
                newBilledDetail.AzukariAmount__c=true;//預り金フラグ
                newBilledDetailList.add(newBilledDetail);
            }
        }
        if(newBilledDetailList!=null){
            insert newBilledDetailList;
        }
        if(billedDetailDoubleList!=null){
            List<BilledDetail__c> fianlList=new List<BilledDetail__c>();
            for(List<BilledDetail__c> b:billedDetailDoubleList)
            {
                for(BilledDetail__c d:b){
					fianlList.add(d);                    
                }
            }
             update fianlList;
        }
       
    }

     public static List<AggregateResult> searchpaymentList(List<Payment__c> oldpaymentList){
        
		string condition='';        
        for(Payment__c p:oldpaymentList){
             condition=condition+'\''+p.Id+'\',';
        }
        if(condition.length()>1){
            condition='WHERE ID in ('+condition.substring(0, condition.length()-1)+')';
        }
        String query='';
        query += '     SELECT   ';
        query += '              Account__c,'; 
        query += '              sum(HoseiAmount__c) HoseiAmount__c,   '; 
        query += '              sum(PaymentAmountHosei__c) PaymentAmountHosei__c,'; 
        query += '              sum(PaymentAmountInput__c) PaymentAmountInput__c'; 
        query += '     FROM Payment__c'; 
        query += '      ' + condition;
		query += '     GROUP BY Account__c ';       
        query += '     ORDER BY Account__c ' ;
        system.debug(query);
             
        List<AggregateResult> paymentList=Database.query(query);
        return paymentList;
    }
    
    private static List<BilledDetail__c> searchBilledDetail(String queryCondition){
            String query='';
            query += '     SELECT   ID,NAME,';
            query += '              Sagaku__c,'; 
            query += '              Billed__c,'; 
            query += '              Agreement__c,'; 
            query += '              PaymentAmount__c,'; 
            query += '              PaymentAmountHosei__c,';
            query += '              TotalLeaseAmount2__c,'; 
            query += '              Billed__r.BilledLeaseAmountSum__c,   '; 
            query += '              Billed__r.Account__c,   '; 
            //query += '              Billed__r.Opportinity__c,   '; 
            query += '              AzukariAmount__c,'; 
            query += '              Billed__r.BilledFlag__c'; 
            query += '     FROM BilledDetail__c'; 
            query += '     WHERE (Sagaku__c > 0 or AzukariAmount__c = true)'; 
            query += '      ' + queryCondition;
            query += '     ORDER BY ID,NAME,Billed__c,AzukariAmount__c DESC' ;
            system.debug(query);
            return Database.query(query);    
        }
        private static List<AggregateResult> getNyukinn(String queryCondition){
            String query='';
            query += '     SELECT        Billed__c,';
            query += '                   Billed__r.Account__c account,   '; 
            //query += '                   Billed__r.Opportinity__c,   '; 
            query += '                   AzukariAmount__c,';
            query += '                   SUM(TotalLeaseAmount2__c) sumrequest';
            query += '             FROM BilledDetail__c';
            query += '             WHERE (Sagaku__c > 0 or AzukariAmount__c = true)';
            query += '              '+ queryCondition;
            query += '             AND Billed__r.BilledFlag__c=false';
            query += '             GROUP BY Billed__c,Billed__r.Account__c,AzukariAmount__c';
            query += '             ORDER BY Billed__c,AzukariAmount__c DESC';
            system.debug(query);
            return Database.query(query);    
        }
    
     private static  List<BilledDetail__c> searchBilledDetail(List<BilledDetail__c> billedDetailListAll,AggregateResult payment){
        List<BilledDetail__c> billedDetailList=new List<BilledDetail__c> ();
        system.debug(billedDetailListAll);
        for(BilledDetail__c bd:billedDetailListAll){
        	system.debug((String)payment.get('Account__c'));
        	system.debug(bd.Billed__r.Account__c);
                if((String)payment.get('Account__c')==bd.Billed__r.Account__c){
                    billedDetailList.add(bd);
            }
        }
        return billedDetailList;
    }
    
    private static  List<AggregateResult> getNyukinn(List<AggregateResult> sumNyukinnAll,AggregateResult payment){
        List<AggregateResult> resultList=new List<AggregateResult> ();
        system.debug(sumNyukinnAll);
        for(AggregateResult bd:sumNyukinnAll){
        	system.debug((String)payment.get('Account__c'));
        	system.debug((String)bd.get('account'));
                if((String)payment.get('Account__c')==(String)bd.get('account')){
                    resultList.add(bd);
                }
        }
        return resultList;
    }
    
     private static  Integer getAzukari(List<BilledDetail__c> billedDetailList){
        Integer azukarikin =0;
        if(billedDetailList!=null){
            for(BilledDetail__c Azukari:billedDetailList){
                if(Azukari.AzukariAmount__c==true){
                    system.debug(Azukari);
                    azukarikin+=Integer.valueOf(Azukari.PaymentAmount__c);
               }
                
            }
        }
         return azukarikin;
    }
    
    private static  Integer getSagaku(List<BilledDetail__c> billedDetailList,AggregateResult payment){
        Integer Sagaku =0;
        if(billedDetailList!=null){
            for(BilledDetail__c billedDetail:billedDetailList){
                if(billedDetail.Sagaku__c!=null &&(String)payment.get('Account__c')==billedDetail.Billed__r.Account__c){
                    Sagaku+=Integer.valueOf(billedDetail.Sagaku__c);
               }
                
            }
        }
         return Sagaku;
    }
    
     /*private static List<BilledDetail__c>  searchBilledDetail(ID accountId,ID billedOpportinity){
        List<BilledDetail__c> billedDetail = [SELECT    ID,NAME,
                                                        Sagaku__c,
                                                        Billed__c,
                                                        Agreement__c,
                                              			PaymentAmount__c,
                                              			TotalLeaseAmount2__c,
                                                        Billed__r.BilledLeaseAmountSum__c,   
                                              			AzukariAmount__c,
                                                        Billed__r.BilledFlag__c
                                                FROM BilledDetail__c
                                                WHERE (Sagaku__c > 0 or AzukariAmount__c = true)
                                                AND Billed__r.Account__c=:accountId
                                              	AND Billed__r.Opportinity__c=:billedOpportinity
                                                ORDER BY Billed__c,AzukariAmount__c DESC
                                             ];
        return billedDetail;
    }*/
    
     /*private static List<AggregateResult> getNyukinn(ID accountId,ID billedOpportinity){
        List<AggregateResult> Nyukinn = [SELECT       Billed__c,
                                                      AzukariAmount__c,
                                              		  SUM(TotalLeaseAmount2__c) sumrequest
                                                FROM BilledDetail__c
                                                WHERE (Sagaku__c > 0 or AzukariAmount__c = true)
                                                AND Billed__r.Account__c=:accountId
                                              	AND Billed__r.Opportinity__c=:billedOpportinity
                                         		AND Billed__r.BilledFlag__c=false
                                                GROUP BY Billed__c,AzukariAmount__c
                                                ORDER BY Billed__c,AzukariAmount__c DESC
                                             ];
         return Nyukinn;
    }*/
}