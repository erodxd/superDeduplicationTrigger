trigger SuperDeDuplication on Lead (before insert) {
    List<Group> dataQualityGroups = [SELECT Id     // queues are stored in the Group SObject
                                       FROM Group  // get it ready for future use
                                      WHERE DeveloperName = 'Data_Quality'
                                      LIMIT 1];

    for (Lead myLead : Trigger.new) {
        if (myLead.Email != null) {
        //searching for matching contacts
        // store results of SOQL query in a list
        List<Contact> matchingContacts = [SELECT Id,
                                                 FirstName, 
                                                 LastName,
                                                 Account.Name
                                            FROM Contact
                                           WHERE Email = :myLead.Email]; // WHERE Contact email = Lead email

        System.debug(matchingContacts.size() + ' contact(s) found.'); // debug message showing how many were found
        // if matches are found...
        if (!matchingContacts.isEmpty()) {
        // assign the lead to the data quality queue
            if (!dataQualityGroups.isEmpty()) {
                myLead.OwnerId = dataQualityGroups.get(0).Id; //only give lead error if you have a data quality queu
            }

            // add the dupe contactIds to the lead description
            String dupeContactsMessage = 'Duplicate contacts found. \n';
            //loop through our duplicate contacts and add them to our string.
            for(Contact matchingContact : matchingContacts) {
                dupeContactsMessage += matchingContact.FirstName + ' ' 
                                     + matchingContact.LastName + ', ' 
                                     + matchingContact.Account.Name + ' ('
                                     + matchingContact.Id + ')\n';

          }
          if (myLead.Description != null) {
            dupeContactsMessage += '\n' + myLead.Description;
          }
          myLead.Description = dupeContactsMessage;
        }
    }
}
}


// Expand dedup logic to also include all of the criteria
// first names begin with the same letter as lead
// last names are identical
// the existing record contains the new record's company name