# Security Checklist
Hello Guys!
In this repository, I would like to share with you a project that I have been developing since November 2018 and today has more than 6,000 lines of code, which is a very complete Security Checklist (probably the most complete and comprehensive you'll find on the Internet), with more than 70 security items to validate your database, going through the part of settings and parameters, permissions, programming objects and much more!!

The results of the checks are organized as follows:
+ **Code**: A unique number to easily identity the validation item
+ **Category**: A way to group the checks according to a logical category I envisioned for these validations
+ **Title**: Verification title, which is a summary of what this item is validating in the database
+ **Result**: Is the result of validation. It informs if the item passed the validation (OK), if it is only an informative item or if it has identified a POSSIBLE problem
+ **How this can be an Issue**: A brief explanation of why this item is being scanned and what security risk it can bring us
+ **Technical explanation**: More technical and specific details of what is being checked on the instance
+ **How to Fix**: Some guidelines on how to correct or circumvent the possible problem identified by the Stored Procedure
+ **Result Details**: XML that returns the records that caused the validation failure and the artifacts identified (some items are limited to TOP (N) records because they can have many records returned in XML)
+ **External Reference**: Link to a article or documentation that might assist in understanding this verification item

This is a project that I ran in several clients here at  Fabrício Lima – Soluções em BD , one of the best BI and SQL Server consulting companies in Brazil, and this is the result of a lot of study, tests and technical discussions with several great professionals of the data platform area and after talking with Fabrício, we decided to release it in a FREE way for the entire technical community.

After using sp_Blitz from Brent Ozar, which I think that is incredible, practical and simple to find a lot of items to check performance, maintenance, auditing, and some security features. Thinking of something as practical as this, I was inspired by this idea to develop stpSecurity_Checklist, trying to deliver something as practical as a “F5” to you.

Stored Procedure official article: 
https://www.dirceuresende.com/blog/stpsecurity_checklist-best-practices-and-security-checklist-for-sql-server/

# Checklist de Segurança (Portuguese version)
Você é Brasileiro ou fala Português?
Saiba que essa Stored Procedure tem suporte atualmente para 2 idiomas (English e Português). Para orientações de utilização, veja o README_ptbr.md ou acesse o artigo em português dessa Stored Procedure:
https://www.dirceuresende.com/blog/sql-server-checklist-de-seguranca-uma-sp-com-mais-de-70-itens-de-seguranca-para-validar-seu-banco-de-dados/
