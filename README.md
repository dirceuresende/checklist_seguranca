# Microsoft SQL Server Security Checklist
Speak up! In this repository I would like to share with you a project that I have been developing since November 2018 and today has more than 4,500 lines of code, which is a very complete Security Checklist (probably the most complete and comprehensive you will find on the Internet), counting with more than 70 Security items to validate your server and database, going through the part of settings and parameters, permissions, programming objects and much more!

The results of the checks are organized as follows:
- Code: Only a unique number to facilitate the identification of the verification item, including when I release the English version (spoiler !!)
- Category: A way to group the checks according to a logical category I envisioned for these validations
- What is checked: Verification title, which is a summary of what this item is validating in the database
- Evaluation: This is the result of validation. It informs if the item has passed validation (OK), if it is just an informative item or has identified a POSSIBLE problem
- Problem Description: A brief explanation of why this item is being checked and what security risk it can bring
- Verification Details: More technical and specific details of what is being verified in the instance
- Correction Tip: Some guidelines on how to correct or circumvent the possible problem identified by the Stored Procedure
- Validation Results: XML that returns the records that caused the validation failure and the identified artifacts (some items are limited to TOP (N) records, as they may have many records returned in XML)
- Reference URL: Link to any article or documentation that may add or assist in understanding this check item

This is a project I use in several clients here at Fabrício Lima, one of the best database and BI consultancies in Brazil, and it is the result of a lot of study, tests and technical discussions with several large professionals in the data area and after to talk to Fabrizio, we have decided to release this FREE of charge for the whole technical community.

This is not a project of Dirceu or Fabrizio, but yours. For this reason, I am releasing the code from this Stored Procedure in Github, so that you all can download, use in your environments and help make it better through commit's and pull requests to bring new features and fixes.

Stored Procedure Article:
https://www.dirceuresende.com/blog/stpsecurity_checklist-best-practices-and-security-checklist-for-sql-server/

# Checklist de Segurança
Fala pessoal!
Nesse repositório eu gostaria de compartilhar com vocês um projeto que venho desenvolvendo desde novembro de 2018 e hoje conta com mais de 4.500 linhas de código, que é um Checklist de Segurança bem completo (provavelmente, o mais completo e abrangente que você encontrará na Internet), contando com mais de 70 itens de Segurança para validar seu banco de dados, passando pela parte de configurações e parâmetros, permissões, objetos de programação e muito mais!

Os resultados das verificações estão organizados da seguinte forma:
+ **Código**: Apenas um número único para facilitar a identificação do item de verificação, inclusive quando eu liberar a versão em inglês (spoiler!!)
+ **Categoria**: Uma forma de agrupar as verificações de acordo com uma categoria lógica que imaginei para essas validações
+ **O que é verificado**: Título da verificação, que é um resumo do que esse item está validando no banco de dados
+ **Avaliação**: É o resultado da validação. Ela informa se o item passou na validação (OK), se é apenas um item informativo ou se identificou um POSSÍVEL problema
+ **Descrição do Problema**: Uma breve explicação sobre o motivo desse item estar sendo verificado e qual o risco de segurança que ele pode nos trazer
+ **Detalhamento da Verificação**: Detalhes mais técnicos e específicos do que está sendo verificado na instância
+ **Sugestão de Correção**: Algumas orientações de como corrigir ou contornar o possível problema identificado pela Stored Procedure
+ **Resultados da Validação**: XML que retorna os registros que causaram a falha da validação e os artefatos identificados (alguns itens são limitados a TOP(N) registros, pois podem tem muitos registros retornados no XML)
+ **URL de Referência**: Link de algum artigo ou documentação que possa agregar ou ajudar no entendimento desse item de verificação
Esse é um projeto que utilizo em vários clientes aqui na Fabrício Lima, um das melhores consultorias de banco de dados e BI do Brasil, e é o resultado de bastante estudo, testes e discussões técnicas com várias grandes profissionais da área de dados e depois de conversar com o Fabrício, resolvemos liberar isso de forma GRATUITA para toda a comunidade técnica.

Esse não é um projeto do Dirceu ou do Fabrício, e sim de vocês. Por este motivo, estou liberando o código dessa Stored Procedure no Github, para que todos vocês possam baixar, utilizar em seus ambientes e ajudar a deixá-la cada vez melhor através de commit’s e pull requests para trazer novos recursos e correções

Artigo dessa Stored Procedure: 
https://www.dirceuresende.com/blog/sql-server-checklist-de-seguranca-uma-sp-com-mais-de-70-itens-de-seguranca-para-validar-seu-banco-de-dados/
