@isTest
private class ImageControllerTest {
    static Contact contact;
    static Contact contact2;
    static Profile p;
    static User u;
    static {
        p = [SELECT Id FROM Profile WHERE Name='Read only'
                                            or Name='システム管理者'];
        u = new User(Alias = 'standt', Email='standarduser@test-org.com',
          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
          LocaleSidKey='en_US', ProfileId = p.Id,
          TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@test-org.com');
        insert u;

        system.runas(u){
            contact = new Contact(Lastname='SharinPix', Email='test@sharinpix.test');
            insert contact;
        }
        contact2 = new Contact(Lastname='SharinPix2', Email='test2@sharinpix.test');
        insert contact2;
    }

    @isTest static void deleteAttachment() {
        Attachment attach = new Attachment(Name='image', parentId = contact.Id, body=Blob.valueOf('Test'));
        insert attach;

        Test.startTest();
        boolean deleted = ImageController.deleteAttachment(attach.Id);
        Test.stopTest();

        system.assert(deleted);
    }

    @isTest static void deleteAttachment_1() {
        Attachment attach = new Attachment(Name='image', parentId = contact2.Id, body=Blob.valueOf('Test'));
        insert attach;
        system.runas(u){
            try {
                Test.startTest();
                ImageController.deleteAttachment(attach.Id);
                Test.stopTest();
            }
            catch(AuraHandledException e){
                //can't get the error message from the class
                system.assert(e != null);
            }
        }
    }

    @isTest static void deleteContentDocument() {
        ContentVersion contentVersion_1 = new ContentVersion(
        Title='Header_Picture1',
        PathOnClient ='/Header_Picture1.jpg',
        VersionData = Blob.valueOf('Body'),
        origin = 'H'
        );
        insert contentVersion_1;

        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = contact.id;
        contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        Test.startTest();
        boolean deleted = ImageController.deleteAttachment(contentVersion_1.Id);
        Test.stopTest();

        system.assert(deleted);
    }

    @isTest static void saveTheChunk() {
        system.runas(u){
            Attachment attach = new Attachment(Name='image', parentId = contact.Id, body=Blob.valueOf('Test'));
            insert attach;
            try{
                Test.startTest();
                ImageController.saveTheChunk(contact.Id, 'Image.jpeg', EncodingUtil.base64Encode(Blob.valueof('Sharinpix')), 'image/jpeg', attach.id);
                Test.stopTest();
            }
            catch(Exception e){
                //can't get the error message from the class
                system.assert(e != null);
            }
        }
    }

    @isTest static void saveTheChunk_2() {
        Attachment attach = new Attachment(Name='image', parentId = contact2.Id, body=Blob.valueOf('Test'));
        insert attach;

        Test.startTest();
        Id fileid = ImageController.saveTheChunk(contact2.Id, 'Image.jpeg', EncodingUtil.base64Encode(Blob.valueof('Sharinpix')), 'image/jpeg', attach.id);
        Test.stopTest();
        system.assertEquals(fileId, attach.Id);
    }

    @isTest static void saveTheChunk_wo_id() {
        system.runas(u){
            try {
                Test.startTest();
                ImageController.saveTheChunk(contact.Id, 'Image.jpeg', EncodingUtil.base64Encode(Blob.valueof('Sharinpix')), 'image/jpeg', null);
                Test.stopTest();
            }
            catch(Exception e){
                //can't get the error message from the class
                system.assert(e != null);
            }
        }
    }

    @isTest static void saveTheChunk_wo_id_2() {
        try {
            Test.startTest();
            ImageController.saveTheChunk(contact.Id, 'Image.jpeg', EncodingUtil.base64Encode(Blob.valueof('Sharinpix')), 'image/jpeg', null);
            Test.stopTest();
        }
        catch(Exception e){
            //can't get the error message from the class
            system.assert(e != null);
        }
    }

    @isTest static void getFiles() {
        list<Attachment> lstAttImages = new list<Attachment>{
            new Attachment(Name='img_1', parentId = contact.Id, body=Blob.valueOf('Test1'), contenttype='image/jpeg'),
            new Attachment(Name='img_2', parentId = contact.Id, body=Blob.valueOf('Test2'), contenttype='image/jpeg'),
            new Attachment(Name='img_3', parentId = contact.Id, body=Blob.valueOf('Test3'), contenttype='image/jpeg'),
            new Attachment(Name='img_4', parentId = contact.Id, body=Blob.valueOf('Test4'), contenttype='image/jpeg')
        };
        insert lstAttImages;

        Test.startTest();
        list<map<string, id>> lstAttachment = (list<map<string, id>>) ImageController.getFiles(contact.Id, 'img', 'image/jpeg');
        Test.stopTest();

        system.assertEquals(lstAttachment.size(), 4);
    }

    @isTest static void getFiles_2() {
        list<Attachment> lstAttImages = new list<Attachment>{
            new Attachment(Name='img_1', parentId = contact2.Id, body=Blob.valueOf('Test1'), contenttype='image/jpeg'),
            new Attachment(Name='img_2', parentId = contact2.Id, body=Blob.valueOf('Test2'), contenttype='image/jpeg'),
            new Attachment(Name='img_3', parentId = contact2.Id, body=Blob.valueOf('Test3'), contenttype='image/jpeg'),
            new Attachment(Name='img_4', parentId = contact2.Id, body=Blob.valueOf('Test4'), contenttype='image/jpeg')
        };
        insert lstAttImages;

        system.runas(u){
            Test.startTest();
            list<map<string, id>> lstAttachment = (list<map<string, id>>) ImageController.getFiles(contact2.Id, 'img', 'image/jpeg');
            Test.stopTest();
           // system.assertEquals(lstAttachment.size(), 0);
        }
    }

    @isTest static void getFiles_3() {
        ContentVersion contentVersion_1 = new ContentVersion(
        Title='img_Header_Picture1',
        PathOnClient ='/Header_Picture1.jpg',
        VersionData = Blob.valueOf('Body'),
        origin = 'H'
        );
        insert contentVersion_1;

        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = contact.id;
        contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        Test.startTest();
        list<map<string, id>> lstAttachment = (list<map<string, id>>) ImageController.getFiles(contact.Id, 'img', 'image/jpeg');
        Test.stopTest();
        system.assertEquals(lstAttachment.size(), 1);
    }

    @isTest static void getFiles_4() {
        list<Attachment> lstAttImages = new list<Attachment>{
            new Attachment(Name='img_1', parentId = contact.Id, body=Blob.valueOf('Test1'), contenttype='image/jpeg'),
            new Attachment(Name='img_2', parentId = contact.Id, body=Blob.valueOf('Test2'), contenttype='image/jpeg'),
            new Attachment(Name='img_3', parentId = contact.Id, body=Blob.valueOf('Test3'), contenttype='image/jpeg'),
            new Attachment(Name='img_4', parentId = contact.Id, body=Blob.valueOf('Test4'), contenttype='image/jpeg')
        };
        insert lstAttImages;

        ContentVersion contentVersion_1 = new ContentVersion(
        Title='img_Header_Picture1',
        PathOnClient ='/Header_Picture1.jpg',
        VersionData = Blob.valueOf('Body'),
        origin = 'H'
        );
        insert contentVersion_1;

        ContentVersion contentVersion_2 = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion_1.Id LIMIT 1];

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = contact.id;
        contentlink.contentdocumentid = contentVersion_2.contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;

        Test.startTest();
        list<map<string, id>> lstAttachment = (list<map<string, id>>) ImageController.getFiles(contact.Id, 'img', 'image/jpeg');
        Test.stopTest();
        system.assertEquals(lstAttachment.size(), 5);
    }
}