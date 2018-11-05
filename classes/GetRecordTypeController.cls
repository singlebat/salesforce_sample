/** 
 * 取引先詳細レコード画面において、「新規見積」クイックアクションより、見積作成コントローラ向けのコントローラ
 */
public class GetRecordTypeController {
	/** 
     * 検索ボタンを押して、検索処理を行う。
     */ 
	@AuraEnabled
	public static List<Option> getEstimateRecordType(){
		List<Option> options = new List<Option>();
        List<RecordType> recordTypes= [select SobjectType, NamespacePrefix, Name, Id
                                       From RecordType 
                                       WHERE SobjectType = 'Estimate__c'
                                      ];
        for (RecordType recordTypeObj : recordTypes ) {
            Option option = new Option();
            option.label = recordTypeObj.Name;
            option.Id = recordTypeObj.Id;
            options.add(option);
        }
	    return options;
	}
    
    /** 
     * RecordType
     */ 
    public class Option {
        /**
         * ラベル
         */
        @AuraEnabled
        public String label { set; get; }
        /**
         * バリュー
         */
        @AuraEnabled
        public String Id { set; get; }
    }
}