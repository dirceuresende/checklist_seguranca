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
