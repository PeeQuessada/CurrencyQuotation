global class batchCurrencyQuote implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful, schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext BC){
       String fildsUpdate = label.currencyUpdate.replaceAll('\\s+', '');
       String query = 'SELECT Id, Name, Error__c';
       for(String currencyAux : fildsUpdate.split(';')){
      	 query += ', ' + currencyAux + '__c';     
       }
       query += ' FROM CurrencyQuotation__c';
       
       return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<CurrencyQuotation__c> scope){
        //Atualiza todos os registros
        for(CurrencyQuotation__c updateCurrency : scope){
             updateCurrency = requestCurrency.requestAPI(updateCurrency);
        } 
        
        Database.upsert(scope, CurrencyQuotation__c.Fields.Name, false);
    }

    global void finish(Database.BatchableContext BC){
        Integer timeSchedule = 86400;
        
        //Verifica se existe algum registro, se não existir cria um novo e agenda um novo batch para um minuto
        if([SELECT Id FROM CurrencyQuotation__c].isEmpty()){
        	insert new CurrencyQuotation__c(Name = label.baseCurrency.replaceAll('\\s+', '')); 
            timeSchedule = 1;
        }
        
        String jobName = 'batchCurrencyQuote in time: ' + System.now();
        system.scheduleBatch(this, jobName, timeSchedule);
    }
    
    global void execute(SchedulableContext SC) {
		database.executebatch(this,50);
    }
 
}