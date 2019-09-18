-- EXEC dbo.stpSecurity_Checklist

GO
IF (OBJECT_ID('dbo.stpSecurity_Checklist') IS NULL) EXEC('CREATE PROCEDURE dbo.stpSecurity_Checklist AS SELECT 1')
GO

--------------------------------------------------------------------------------------------------------------------
--
-- stpSecurity_Checklist - 1.0.4 (21/06/2019)
-- Checklist de segurança para ambientes SQL Server - Mais de 70 validações de segurança!!
-- 
-- Precisa de ajuda para corrigir algum problema?
-- contato@fabriciolima.net
--
--------------------------------------------------------------------------------------------------------------------

ALTER PROCEDURE dbo.stpSecurity_Checklist (
    @language VARCHAR(2) = NULL,
    @heavy_operations BIT = 1
)
AS 
BEGIN


    SET NOCOUNT ON


    IF (OBJECT_ID('tempdb..#Resultado') IS NOT NULL) DROP TABLE #Resultado
    CREATE TABLE #Resultado (
        Id_Verificacao INT NOT NULL PRIMARY KEY,
        Ds_Categoria VARCHAR(100) NULL,
        Ds_Titulo VARCHAR(100) NULL,
        Ds_Resultado VARCHAR(100) NULL,
        Ds_Descricao VARCHAR(MAX) NULL,
        Ds_Verificacao VARCHAR(MAX) NULL,
        Ds_Sugestao VARCHAR(MAX) NULL,
        Ds_Referencia VARCHAR(500) NULL,
        Ds_Detalhes XML NULL
    )
    

    DECLARE
        @Resultado XML,
        @ResultadoString VARCHAR(MAX),
        @Versao INT,
        @Quantidade INT,
        @Data DATETIME,
        @IsAmazonRDS BIT = (CASE WHEN LEFT(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(8000)), 8) = 'EC2AMAZ-' AND LEFT(CAST(SERVERPROPERTY('MachineName') AS VARCHAR(8000)), 8) = 'EC2AMAZ-' AND LEFT(CAST(SERVERPROPERTY('ServerName') AS VARCHAR(8000)), 8) = 'EC2AMAZ-' THEN 1 ELSE 0 END),
        @Query VARCHAR(MAX),
        @Dt_Hoje DATE = GETDATE()
    

    SET @Versao = (CASE LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 2)
        WHEN '8.' THEN 2000
        WHEN '9.' THEN 2005
        WHEN '10' THEN 2008
        WHEN '11' THEN 2012
        WHEN '12' THEN 2014
        WHEN '13' THEN 2016
        WHEN '14' THEN 2017
        WHEN '15' THEN 2019
        ELSE 2019
    END)

    
    SET @language = (CASE
        WHEN NULLIF(LTRIM(RTRIM(@language)), '') IS NULL THEN (SELECT CASE WHEN [value] IN (5, 7, 27) THEN 'pt' ELSE 'en' END FROM sys.configurations WHERE [name] = 'default language')
        ELSE @language 
    END)

    
    ---------------------------------------------------------------------------------------------------------------
    -- Idiomas
    ---------------------------------------------------------------------------------------------------------------

    IF (@language = 'pt')
    BEGIN
    
        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
            Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (-8, 'Avisos', 'Copyright', 'Informativo', 'stpChecklist_Seguranca 1.0', NULL, NULL, NULL, '<Detalhes><Copyright>Stored Procedure desenvolvida por Dirceu Resende</Copyright><Website>https://www.dirceuresende.com</Website></Detalhes>'),
            (-7, 'Avisos', 'Versão', 'Informativo', @@VERSION, NULL, NULL, NULL, NULL),
            (-6, 'Avisos', 'Informações da máquina', 'Informativo', NULL, NULL, NULL, NULL, NULL),
            (-5, 'Avisos', 'Data de Inicialização', 'Informativo', NULL, NULL, NULL, NULL, NULL),
            (-4, 'Avisos', 'Parâmetros de Inicialização', 'Informativo', 'Verifica os parâmetros de inicialização utilizados pela instância do SQL Server', NULL, NULL, NULL, NULL),
            (-3, 'Avisos', 'Instâncias no servidor', 'Informativo', NULL, NULL, NULL, NULL, NULL),
            (-2, 'Avisos', 'Instâncias rodando em CLUSTER', 'Informativo', (CASE WHEN CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(10)) = '1' THEN 'SIM' ELSE 'NÃO' END), NULL, NULL, NULL, NULL),
            (-1, 'Avisos', 'Ajuda', 'Informativo', 'Encontrou algum problema e precisa de ajuda? Solicite agora uma consultoria e protega seu ambiente com uma equipe de especialistas', NULL, NULL, NULL, '<Contatos><Whatsapp>https://bit.ly/dirceuresende</Whatsapp><Telegram>https://t.me/dirceuresende</Telegram><Skype>@dirceuresende</Skype><Email>contato@fabriciolima.net</Email></Contatos>'),
            (0, '----------------------', '----------------------', '----------------------', '----------------------', NULL, NULL, NULL, NULL),
            (
                1, 
                'Configuração',
                'Trustworthy', 
                NULL, 
                'Configuração que permite executar comandos maliciosos dentro do database e "tomar o controle" de outros databases por usuários que estão na role db_owner',
                'Verifica se algum database possui a propriedade "TRUSTWORTHY" habilitado',
                'Desative a propriedade "TRUSTWORTHY" de todos os databases. Caso utilize para assemblies SQLCLR, utilize chaves de criptografia',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/trustworthy-database-property?view=sql-server-2017',
                NULL
            ),
            (
                2, 
                'Configuração',
                'Auditoria de Falhas de Login', 
                NULL, 
                'Configuração que permite auditar falhas de login na instância quando usuários erram a senha. Essa configuração é recomendável estar ativada para conseguir identificar possíveis ataques de força-bruta na instância', 
                'Verifica se a instância está gravando no log quando o usuário erra uma senha',
                'Ativar a auditoria de conexão para falhas de login',
                'https://www.mssqltips.com/sqlservertip/1735/auditing-failed-logins-in-sql-server/',
                NULL
            ),
            (
                3, 
                'Configuração',
                'Autenticação Windows Apenas',
                NULL, 
                'Configuração que permite a autenticação utilizando Segurança Integrada do Windows (mais seguro), mas também autenticação SQL Server, utilizando usuário e senha (menos seguro). Essa configuração não é exatamente um problema, pois existem aplicações legadas que requerem autenticação SQL Server, mas é uma boa prática evitar esse cenário, quando possível.',
                'Verifica se a instância está permitindo conexões de logins SQL Server',
                'Desativar a autenticação de logins SQL Server, quando possível',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/choose-an-authentication-mode?view=sql-server-2017',
                NULL
            ),
            (
                4, 
                'Configuração',
                'Ad hoc distributed queries', 
                NULL, 
                'Configuração que permite executar possíveis comandos remotamente através de OPENROWSET/OPENDATASOURCE. Os possíveis problemas de segurança causados por essa configuração é a possibilidade do provider conter algum bug de segurança, possibilidade de um servidor comprometido acessar dados de um servidor ainda não comprometido ou mesmo um servidor comprometido enviar de volta informações durante ataques hackers',
                'Verifica se a configuração "Ad hoc distributed queries" está habilitada no sp_configure',
                'Desativar a configuração "Ad hoc distributed queries" caso não esteja utilizando OPENROWSET/OPENDATASOURCE e nem o SQL Server 2005',
                'https://cuttingedge.it/blogs/steven/pivot/entry.php?id=44',
                NULL
            ),
            (
                5, 
                'Configuração',
                'cross db ownership chaining', 
                NULL, 
                'Configuração que permite que uma pessoa acesse objetos que ela não tenha acesso em outro database através de cenários específicos de "cross db ownership chaining"',
                'Verifica se a configuração "cross db ownership chaining" está ativa no sp_configure',
                'Desative a configuração "cross db ownership chaining" caso não esteja utilizando esse recurso (sua utilização não é muito comum)',
                'http://www.sqlservercentral.com/articles/Stairway+Series/123545/',
                NULL
            ),
            (
                6, 
                'Configuração',
                'Atualizações do SQL Server/Windows', 
                NULL, 
                'Essa validação identifica quando a instância está há mais de 60 dias sem ser reiniciada, indicando que atualizações de Windows e do SQL Server não estão sendo aplicados',
                'Verifica a quantos dias o serviço do SQL Server está online',
                'Aplique atualizações de Windows e também Service Packs e Cumulative Updates do SQL Server. Muitas atualizações são correções e pacotes de segurança',
                'https://sqlserverbuilds.blogspot.com/',
                NULL
            ),
            (
                7, 
                'Configuração',
                'Databases sem verificação de página', 
                NULL, 
                'Configuração que permite que o SQL Server grave um CHECKSUM em cada página à medida que vai para o armazenamento e, em seguida, verifique o CHECKSUM novamente quando os dados são lidos do disco para tentar garantir a integridade dos dados. Isso pode gerar uma pequena sobrecarga de CPU, mas normalmente vale a pena recuperar-se da corrupção',
                'Verifica se algum database está utilizando algum algoritmo de validação de página diferente do CHECKSUM (NONE ou TORN_PAGE)',
                'Altere o algoritmo de validação de página de todos os databases para CHECKSUM',
                'https://www.brentozar.com/blitz/page-verification/',
                NULL
            ),
            (
                8, 
                'Configuração',
                'Default trace habilitado', 
                NULL,
                'Configuração que permite que o SQL Server colete algumas informações da instância pelo Default Trace, como alguns comandos de DDL, DCL, etc.',
                'Verifica se o trace padrão do SQL Server está habilitado e executando',
                'Habilite o trace padrão do SQL Server para auditar eventos',
                'https://www.dirceuresende.com/blog/utilizando-o-trace-padrao-do-sql-server-para-auditar-eventos-fn_trace_gettable/',
                NULL
            ),
            (
                9, 
                'Configuração',
                'scan for startup procs', 
                NULL,
                'Configuração que permite que uma pessoa monitore quais objetos são executados na inicialização do SQL Server e crie códigos maliciosos nesses objetos.',
                'Verifica se a configuração "scan for startup procs" está habilitada na instância através da sp_configure',
                'Desative essa configuração caso não esteja realizando nenhuma validação do que é executado durante a inicialização do SQL Server',
                'https://docs.microsoft.com/pt-br/sql/database-engine/configure-windows/configure-the-scan-for-startup-procs-server-configuration-option?view=sql-server-2017',
                NULL
            ),
            (
                10, 
                'Configuração',
                'DatabaseMail XPs', 
                NULL,
                'Configuração que permite que uma pessoa envie e-mails e informações do banco para outras pessoas utilizando o DatabaseMail. Embora isso seja bastante utilizado por sistemas e alertas, você deve verificar se isso realmente é necessário na instância e se está sendo utilizado. Caso não esteja, desative essa opção.',
                'Verifica se a configuração "Database Mail XPs" está habilitada na sp_configure',
                'Desative essa configuração caso não tenha nenhuma rotina que envie e-mails pelo banco de dados e que não possa ser enviado pelo SSIS, por exemplo',
                'https://www.sqlshack.com/securing-sql-server-surface-area/',
                NULL
            ),
            (
                11, 
                'Configuração',
                'SQL Mail XP', 
                NULL,
                'Configuração que permite que uma pessoa envie e-mails e informações do banco para outras pessoas utilizando o SQL Mail XP (Disponível até o SQL Server 2012. Após isso, foi substituído pelo DatabaseMail). Embora isso seja bastante utilizado por sistemas e alertas, você deve verificar se isso realmente é necessário na instância e se está sendo utilizado. Caso não esteja, desative essa opção.',
                'Verifica se a configuração "SQL Mail XP" está habilitada na sp_configure',
                'Desative essa configuração caso não tenha nenhuma rotina que envie e-mails pelo banco de dados e que não possa ser enviado pelo SSIS, por exemplo',
                'https://www.sqlshack.com/securing-sql-server-surface-area/',
                NULL
            ),
            (
                12, 
                'Configuração',
                'Remote Admin Connections (DAC)', 
                NULL,
                'Configuração que permite que usuários administradores (sysadmin) possam logar na instância mesmo quando ela está com algum problema que impede o logon ou quando o limite de conexões da instância é atingido. Essa configuração deve ser habilitada para que seja possível utilizá-la em casos de emergência.',
                'Verifica se a configuração "remote admin connections" está habilitada na sp_configure',
                'Habilite a configuração "remote admin connections" na sp_configure',
                'https://www.dirceuresende.com/blog/habilitando-e-utilizando-a-conexao-remota-dedicada-para-administrador-dac-no-sql-server/',
                NULL
            ),
            (
                13, 
                'Configuração',
                'Remote Access', 
                NULL,
                'Configuração que permite que usuários executem Stored Procedures remotamente através de Linked Server, permitindo que um hacker possa utilizar uma instância comprometida para realizar ataques de DDoS em outra instância da rede. Esse parâmetro está marcado como Deprecated e caso não seja utilizado por nenhuma rotina, deve ser desativado.',
                'Verifica se a configuração "remote access" está habilitada na sp_configure',
                'Desabilite a configuração "remote access" caso você não utilize Stored Procedures remotamente, utilizando Linked Servers',
                'https://docs.microsoft.com/pt-br/sql/database-engine/configure-windows/configure-the-remote-access-server-configuration-option?view=sql-server-2017',
                NULL
            ),
            (
                14, 
                'Configuração',
                'SMO and DMO XPs', 
                NULL,
                'Configuração que permite que usuários programem no SQL Server utilizando linguagens de programação como C#, VB e PowerShell. Caso não esteja sendo utilizado, a boa prática é desativar esse recurso. Obs: Caso esteja utilizando o SSMS 17 para acessar o SQL Server 2005, pode ser necessário habilitar esse parâmetro para conseguir utilizar o SSMS',
                'Verifica se a configuração "SMO and DMO XPs" está habilitada na sp_configure',
                'Desative a configuração "SMO and DMO XPs" caso não utilize programação SMO',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-04-03/finding/V-15211',
                NULL
            ),
            (
                15, 
                'Configuração',
                'Server Trigger Habilitada', 
                NULL, 
                'Essa configuração valida se alguma trigger a nível de servidor está habilitada no ambiente. Esse recurso pode ser utilizado por hackers para impedir o logon de determinados usuários',
                'Verifica se alguma trigger a nível de servidor está habilitada na instância',
                'Valide se essa server trigger está correta e não influi em nenhum risco para os usuários',
                NULL,
                NULL
            ),
            (
                16, 
                'Configuração',
                'Trace Habilitado',
                NULL, 
                'Essa configuração valida se algum trace está habilitado no ambiente. Esse recurso permite analisar e capturar informações das consultas executadas no banco. Da mesma forma que isso pode ser utilizado para fins de auditoria, pode também ser utilizado para capturar dados sensíveis por pessoas mal intencionadas',
                'Verifica se algum trace (que não o trace default) está habilitado na instância',
                'Valide se esse trace realmente foi criado pelo time de DBA e não influi em nenhum risco para os usuários',
                NULL,
                NULL
            ),
            (
                17, 
                'Configuração',
                'Extended Events (XE) Habilitado',
                NULL, 
                'Essa configuração valida se algum Extended Event (XE) está habilitado no ambiente. Esse recurso permite analisar e capturar informações das consultas executadas no banco. Da mesma forma que isso pode ser utilizado para fins de auditoria, pode também ser utilizado para capturar dados sensíveis por pessoas mal intencionadas',
                'Verifica se algum Extended Event (que não os padrões do SQL Server) está habilitado na instância',
                'Valide se esse XE realmente foi criado pelo time de DBA e não influi em nenhum risco para os usuários',
                NULL,
                NULL
            ),
			(
                18, 
                'Configuração',
                'AUTO_CLOSE desativado para bancos de dados contidos',
                NULL, 
                'Como a autenticação de usuários para bancos de dados contidos ocorre no banco de dados e não no nível do servidor \ instância, o banco de dados deve ser aberto sempre para autenticar um usuário. A abertura / fechamento frequente do banco de dados consome recursos adicionais do servidor e pode contribuir para uma negação de serviço.',
                'Verifica se algum banco de dados contido tem AUTO_CLOSE ativado.',
                'Essa configuração deve ser desativada para interromper a abertura e o fechamento frequentes de conexões de bancos de dados',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/databases/security-best-practices-with-contained-databases?view=sql-server-2017',
                NULL
            ),
			(
                19, 
                'Configuração',
                'Número baixo de registros de erros retidos',
                NULL, 
                'Os arquivos de log de erros do SQL Server devem ser protegidos contra perda.',
                'Os arquivos de log devem ser submetidos a backup antes de serem sobrescritos. Freqüentemente, um SQL Server é reiniciado várias vezes para tentar resolver um problema. Isso faz com que o log de erros seja reciclado e você perderá informações importantes sobre a solução de problemas. Este é um item marcado do Center for Internet Security (CIS).',
                'Ajuste o número de logs para evitar perda de dados. O valor padrão de 6 talvez seja insuficiente para um ambiente de produção.',
                'https://www.brentozar.com/archive/2015/09/forgotten-maintenance-cycling-the-sql-server-error-log/',
                NULL
            ),
            (
                100, 
                'Segurança de Usuários',
                'Falha de usuário/senha', 
                NULL, 
                'Verifica quantas tentativas de login tiveram falha por usuário e senha incorretos',
                'Verifica no log do SQL Server os eventos de falha de login por senha incorreta',
                'Verifique a origem dessas conexões e caso não as conheça, bloqueie o IP no Firewall. Uma boa sugestão é alterar periodicamente a senha dos usuários SQL e utilizar senhas fortes para evitar invasões',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-ataques-de-forca-bruta-no-seu-banco-de-dados/',
                NULL
            ),
            (
                101, 
                'Segurança de Usuários',
                'Usuário SA', 
                NULL, 
                'Usuário padrão do SQL Server que possui a permissão mais elevada possível (sysadmin). Deve ser desativado e renomeado para evitar possíveis ataques hackers',
                'Verifica se o usuário "sa" está habilitado',
                'Desative o usuário "sa" e altere o nome desse usuário',
                'https://www.dirceuresende.com/blog/sql-server-como-desativar-o-login-sa-minimizando-impactos/',
                NULL
            ),
            (
                102, 
                'Segurança de Usuários',
                'Usuários Órfãos', 
                NULL, 
                'Usuários que não possuem logins associados. Provavelmente algum erro de mapeamento. Esses usuários devem ser removidos ou remapeados com o respectivo login. Esse tipo de situação pode ser utilizada por hackers para tentar acessar bases que esses usuários possuem permissão',
                'Verifica usuários criados nos databases e que não possuem logins associados na instância',
                'Tente refazer o mapeamento com a sp_change_users_login. Caso o login realmente não exista, tenta analisar se esse usuário pode ser removido',
                'https://www.dirceuresende.com/blog/identificando-e-resolvendo-problemas-de-usuarios-orfaos-no-sql-server-com-a-sp_change_users_login/',
                NULL
            ),
            (
                103, 
                'Segurança de Usuários',
                'Usuários sem políticas de troca de senha', 
                NULL, 
                'Logins SQL Server que não possuem política de senha, ou seja, a senha não expira e/ou não tem exigências de complexidade definidas. Caso seja um usuário de aplicação, esse alerta pode ser ignorado, mas caso seja login de um usuário, ele deve ser forçado a trocar a senha regularmente e ter senhas difíceis de serem quebradas',
                'Verifica os logins que não possuem as opções de expiração de senha e/ou conformidade com as políticas de senha',
                'Habilite as opções de "enforce password policy" e "enforce password expiration" na tela de propriedades do login',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017',
                NULL
            ),
            (
                104, 
                'Segurança de Usuários',
                'Usuários com senha antiga', 
                NULL, 
                'Logins SQL Server que a senha não expira e não é alterada há mais de 180 dias. Mesmo sendo um usuário de aplicação, a senha do usuário deve ser alterada regularmente para evitar possíveis ataques hackers',
                'Verifica se a senha do login SQL Server não é alterada há mais de 180 dias',
                'Altere a senha de todos os logins SQL Server regularmente para evitar vazamentos de senhas',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017',
                NULL
            ),
            (
                105, 
                'Segurança de Usuários',
                'Usuários com senha fraca', 
                NULL, 
                'Logins SQL Server que possuem senhas fracas e que foram facilmente quebradas utilizando essa Stored Procedure',
                'Tenta quebrar a senha dos logins SQL utilizando a função PWDCOMPARE e uma pequena base de senhas mais comuns',
                'Altere regularmente a senha dos logins SQL e utilize senhas fortes e complexas para dificultar ataques de força bruta',
                'https://www.dirceuresende.com/blog/sql-server-como-identificar-senhas-frageis-vazias-ou-iguais-ao-nome-do-usuario/',
                NULL
            ),
            (
                106, 
                'Segurança de Usuários',
                'Usuários sem Permissão', 
                NULL, 
                'Usuários que não possuem nenhuma permissão no database, ou seja, devem estar criados no banco sem nenhuma necessidade. Esses usuários provavelmente podem ser excluídos do database com segurança.',
                'Identifica usuários de databases que não estão em nenhuma role e nem possuem nenhuma permissão no banco',
                'Analise se esses usuários podem ser removidos',
                NULL,
                NULL
            ),
            (
                107, 
                'Segurança de Usuários',
                'Usuários AD sem utilizar Kerberos', 
                NULL, 
                'Identifica se o protocolo de autenticação NTLM está sendo utilizado ao invés do Kerberos, que é um protocolo mais seguro de comunicação entre servidores e permite do Double-Hop',
                'Identifica usuários com autenticação AD na sys.dm_exec_connections que não estão utilizando o Kerberos',
                'Analise se o SPN da instância está configurado corretamente nos registros do AD',
                'https://www.dirceuresende.com/blog/sql-server-autenticacao-ad-kerberos-ntlm-login-failed-for-user-nt-authorityanonymous-logon/',
                NULL
            ),
            (
                108, 
                'Segurança de Usuários',
                'Permissão VIEW ANY DATABASE', 
                NULL, 
                'Identifica se existe algum usuário com permissão de VIEW ANY DATABASE, permitindo assim, que ele veja o nome de todos os databases da instância',
                'Analisa na DMV sys.server_permissions se algum usuário com autenticação SQL tenha permissão de VIEW ANY DATABASE',
                'Remova a permissão VIEW ANY DATABASE da role padrão public e de todos os usuários que não acessam o SQL Server pelo SSMS, especialmente sistemas. Utilizar o grupo do AD DOMINIO\Domain Users pode ser uma alternativa mais segura ao public',
                'https://www.dirceuresende.com/blog/sql-server-como-ocultar-os-databases-para-usuarios-nao-autorizados/',
                NULL
            ),
			(
                109, 
                'Segurança de Usuários',
                'Grupos do Windows BUILTIN', 
                NULL, 
                'Por padrão, esse grupo tem direitos de administrador do sistema do SQL Server para o SQL Server quando ele é instalado. O mesmo nível de direitos padrão também é concedido ao grupo BUILTIN\Administrators no SQL Server 2005 durante a instalação.',
                'Os grupos BUILTIN (Administradores, Todos, Usuários Autenticados, Convidados, etc.) geralmente contêm associações muito amplas que não atendem à melhor prática de garantir que apenas os usuários necessários tenham acesso a uma instância do SQL Server. Esses grupos não devem ser usados ​​para qualquer nível de acesso em uma instância do Mecanismo de Banco de Dados do SQL Server.',
                'O BUILTIN em grupos pode ser facilmente removido do SQL Server para evitar esse problema de segurança, mas antes você deve criar um grupo AD mais restritivo contendo apenas as contas de usuário necessárias',
                'https://www.mssqltips.com/sqlservertip/1017/security-issues-with-the-sql-server-builtin-administrators-group/',
                NULL
            ),
			(
                110, 
                'Segurança de Usuário',
                'Grupos Locais do Windows', 
                NULL, 
                'Grupos locais do Windows não devem ser usados ​​como logins para instâncias do SQL Server.',
                'Permitir grupos locais do Windows como SQL Logins fornece uma brecha na qual qualquer pessoa com direitos de administrador no nível do sistema operacional (e sem direitos do SQL Server) pode adicionar usuários aos grupos locais do Windows e, assim, dar acesso a eles ou outras pessoas à instância do SQL Server.',
                'O Windows local em grupos pode ser facilmente removido do SQL Server para evitar esse problema de segurança, mas antes você deve criar um grupo AD mais restritivo contendo apenas as contas de usuário necessárias.',
                NULL,
                NULL
            ),
            (
                200, 
                'Programação',
                'xp_cmdshell', 
                NULL, 
                'Configuração que permite executar comandos maliciosos dentro do database através do xp_cmdshell',
                'Verifique se a configuração "xp_cmdshell" está habilitada na sp_configure',
                'Desabilite essa configuração caso não esteja utilizando em nenhuma rotina. Caso esteja, tente utilizar outra solução, como o SQLCLR, para prover essa funcionalidade',
                'http://www.sqlservercentral.com/blogs/brian_kelley/2009/11/13/why-we-recommend-against-xp-cmdshell/',
                NULL
            ),
            (
                201, 
                'Programação',
                'Ole Automation', 
                NULL, 
                'Configuração que permite executar comandos maliciosos dentro do database através de procedures OLE Automation',
                'Verifique se a configuração "Ole Automation Procedures" está habilitada na sp_configure',
                'Desabilite essa configuração caso não esteja utilizando em nenhuma rotina. Caso esteja, tente utilizar outra solução, como o SQLCLR, para prover essa funcionalidade',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-04-03/finding/V-2472',
                NULL
            ),
            (
                202, 
                'Programação',
                'SQLCLR', 
                NULL, 
                'Configuração que permite executar comandos maliciosos dentro do database através de procedures SQLCLR',
                'Verifica se a configuração "clr enabled" está habilitada na sp_configure',
                'Desabilite a configuração "clr enabled" caso não esteja utilizando nenhuma biblioteca SQLCLR',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-2017',
                NULL
            ),
            (
                203, 
                'Programação',
                'SQLCLR Unsafe/External Access', 
                NULL, 
                'Configuração que permite executar comandos maliciosos dentro do database através de procedures SQLCLR com permissão Unsafe/External Access',
                'Verifica se algum assembly, de algum database, foi criado com a PERMISSION_SET = UNSAFE ou EXTERNAL_ACCESS',
                'Valide se essa biblioteca está realmente sendo utilizada e assine o assembly utilizando certificado de criptografia',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-2017',
                NULL
            ),
            (
                204, 
                'Programação',
                'Scripts Externos (R, Python ou Java)', 
                NULL, 
                'Configuração que permite executar comandos maliciosos dentro do database através de scripts em linguagem R (SQL 2016), Python (SQL 2017) ou Java (SQL 2019)',
                'Verifica se a configuração "external scripts enabled" está habilitada na sp_configure',
                'Desabilite a configuração "external scripts enabled" caso não utilize scripts Python, R ou Java no SQL Server',
                'https://www.stigviewer.com/stig/ms_sql_server_2016_instance/2018-03-09/finding/V-79347',
                NULL
            ),
            (
                300, 
                'Segurança dos Dados',
                'Transparent Data Encryption (TDE)', 
                NULL, 
                'Configuração que permite criptografar os dados do banco, backups e logs para evitar acesso indevido aos dados',
                'Valida os databases que não possuem o TDE habilitado',
                'Habilite o TDE nas bases do SQL Server 2008+ para criptografar os dados, logs e backups automaticamente',
                'https://www.dirceuresende.com/blog/sql-server-2008-como-criptografar-seus-dados-utilizando-transparent-data-encryption-tde/',
                NULL
            ),
            (
                301, 
                'Segurança dos Dados',
                'Databases sem Backup', 
                NULL, 
                'Validação que identifica bancos de dados SEM BACKUP, o que pode causar um tragédia caso algum dado fique corrompido',
                'Verifica bancos de dados que não possuem nenhum tipo de backup nos últimos 7 dias',
                'Crie rotinas automáticas para backup FULL + DIFF + LOG em ambiente de produção ou backup FULL diário para ambientes não críticos',
                'https://edvaldocastro.com/politicabkp/',
                NULL
            ),
            (
                302, 
                'Segurança dos Dados',
                'Backups sem Criptografia', 
                (CASE WHEN @Versao <= 2008 THEN 'Não suportado' WHEN NULL IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END), 
                'Validação que identifica bancos de dados com backup sem criptografia, o que possibilita que terceiros consigam ler os dados caso eles consigam acesso os arquivos de backup',
                'Verifica backups de bancos de dados sem criptografia',
                'Implemente TDE no database ou altere a sua rotina de backup para criptografar os backups',
                'https://www.tiagoneves.net/blog/criando-um-backup-criptografado-no-sql-server/',
                NULL
            ),
            (
                303, 
                'Segurança dos Dados',
                'Recovery Model FULL sem Backup de LOG', 
                NULL, 
                'Validação que identifica bancos de dados com recovery model definido como FULL, mas sem rotina de backup de log configurada, o que provavelmente é uma configuração incorreta ou falta de rotina de backup',
                'Verifica bancos de dados com recovery model FULL, mas sem rotina de backup de log',
                'Implemente uma rotina automática de backup de log ou altere o Recovery Model para SIMPLE, caso não seja um ambiente crítico e dados após o último possam ser perdidos em caso de falha',
                'https://www.brentozar.com/blitz/full-recovery-mode-without-log-backups/',
                NULL
            ),
            (
                304, 
                'Segurança dos Dados',
                'Extensão dos arquivos dos databases',
                NULL, 
                'Essa configuração valida se o SQL Server está utilizando as extensões padrão para arquivo de dados, logs e backups, que são alvos de Ransomwares, como o WannaCry',
                'Verifica se os databases do SQL Server estão utilizando as extensão padrão para arquivos de dados (MDF) e logs (LDF)',
                'Utilize extensões personalizadas para os arquivos de dados, logs e backups, dificultando que vírus e ransonwares ataquem os arquivos de database do SQL Server',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
                NULL
            ),
            (
                305, 
                'Segurança dos Dados',
                'Extensão dos arquivos de backup',
                NULL, 
                'Essa configuração valida se o SQL Server está utilizando as extensões padrão para arquivo de backup do banco, que são alvos de Ransomwares, como o WannaCry',
                'Verifica se os databases do SQL Server estão utilizando as extensão padrão para arquivos de backup (BAK)',
                'Utilize extensões personalizadas para os arquivos de backups, dificultando que vírus e ransonwares ataquem os arquivos de backup do SQL Server',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
                NULL
            ),
            (
                306, 
                'Segurança dos Dados',
                'Armazenamento dos Backups',
                NULL, 
                'Essa configuração valida se o SQL Server está configurado para utilizar outro destino de backup que não seja apenas o disco',
                'Verifica se os databases do SQL Server estão utilizando soluções alternativas para armazenamento dos arquivos de backup, como nuvem e/ou fita',
                'Utilize mais de um local para armazenar seus arquivos de backup do SQL Server, pois caso você armazene em um local físico apenas, você pode perder todos os casos em caso de catástrofe',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
                NULL
            ),
            (
                400, 
                'Permissões',
                'Permissão CONTROL SERVER', 
                NULL, 
                'Permissão elevada que permite controlar e até mesmo, desligar a instância SQL Server',
                'Verifica usuários com permissão de CONTROL SERVER ou permissões elevadas na instância',
                'Remova as permissões elevadas desses usuários, caso não sejam DBAs e as permissões sejam realmente necessárias e justificáveis',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2012_database_instance/2017-04-03/finding/V-41268',
                NULL
            ),
            (
                401, 
                'Permissões',
                'Usuários nas roles sysadmin/securityadmin', 
                NULL, 
                'Permissão elevada que permite executar comandos como outro login, controlar e até mesmo, desligar a instância SQL Server',
                'Verifica os usuários que estão nas server roles sysadmin e/ou securityadmin',
                'Remova esses usuários dessas duas roles caso não sejam DBAs e seja realmente necessário e justificável que esses usuários estejam nessas roles',
                'https://renatomsiqueira.com/category/security/roles-security/',
                NULL
            ),
            (
                402, 
                'Permissões',
                'IMPERSONATE ANY LOGIN', 
                NULL, 
                'Permissão que possibilita que um determinado login possa executar comandos como QUALQUER USUÁRIO, inclusive, um usuário sysadmin',
                'Verifica os usuários que possuem a permissão "IMPERSONATE ANY LOGIN" na instância',
                'Remova essa permissão desses usuários',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                403, 
                'Permissões',
                'IMPERSONATE LOGIN', 
                NULL, 
                'Permissão que possibilita que um determinado login possa executar comandos como determinados logins da instância. Verificar se os login impersonáveis possuem permissões elevadas',
                'Verifica os usuários que possuem a permissão "IMPERSONATE LOGIN" na instância',
                'Remova essa permissão dos usuários, a não ser que exista algum motivo plausível que justifique que um login para executar comandos como outra pessoa',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                404, 
                'Permissões',
                'IMPERSONATE LOGIN em logins sysadmin/securityadmin', 
                NULL, 
                'Permissão que possibilita que um determinado login possa executar comandos como determinados logins da instância em usuários com permissões elevadas (securityadmin/sysadmin/CONTROL SERVER/IMPERSONATE ANY LOGIN)',
                'Identifica usuários com privilégio de "IMPERSONATE LOGIN" em contas de usuários que são sysadmin/security admin ou possuem privilégios elevados',
                'Remova essa permissão de IMPERSONATE LOGIN" desses usuários',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                405, 
                'Permissões',
                'db_owner e db_securityadmin', 
                NULL, 
                'Permissão que possibilita que um determinado usuário possa executar qualquer ação em um database específico',
                'Verifica em todos os databases, quem são os usuários nas roles db_owner e db_securityadmin',
                'Remova esses usuários dessas database roles e analise como substituí-las, como uma db_ddladmin, por exemplo, ou outra role com ainda menos permissões',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-2017',
                NULL
            ),
            (
                406, 
                'Permissões',
                'IMPERSONATE USER', 
                NULL, 
                'Permissão que possibilita que um determinado usuário possa executar ações como se fosse outro usuário',
                'Verifica em todos os databases quais são os usuários que possuem permissão de "IMPERSONATE USER"',
                'Remove essa permissão dos usuários caso não haja nenhuma justificativa válida para um usuário executar comandos no database como se fosse outra pessoa',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                407, 
                'Permissões',
                'Role PUBLIC com permissões', 
                NULL, 
                'Validação que garante que a role PUBLIC não tem nenhuma permissão elevada na instância, já que todos os usuários da instância estão nessa role automaticamente. Todas as permissões que essa role possuir, podem ser utilizadas por QUALQUER usuário da instância.',
                'Verifica em todos os databases e na instância, todas as permissões que a role PUBLIC possui',
                'Remova todas as permissões da role public',
                'https://basitaalishan.com/2013/04/04/the-public-role-do-not-use-it-for-database-access/',
                NULL
            ),
            (
                408, 
                'Permissões',
                'Usuário GUEST com permissões', 
                NULL, 
                'Validação que garante que o usuário GUEST não tem nenhuma permissão na instância. Esse usuário especial permite acesso a qualquer login que não tenha usuário mapeado em um database e por isso, deve ter o privilégio de CONNECT revogado em todos os databases',
                'Verifica se o usuário GUEST possui alguma permissão na instância',
                'Remova todas as permissões do usuário GUEST que não seja CONNECT nas databases msdb, master e tempdb',
                'https://basitaalishan.com/2012/08/28/sql-server-guest-user-still-a-serious-security-threat/',
                NULL
            ),
            (
                409, 
                'Permissões',
                'Usuários com permissão UNSAFE/EXTERNAL ASSEMBLY', 
                NULL, 
                'Permissão que possibilita que um determinado login possa criar assemblies com o modo de segurança UNSAFE/EXTERNAL ACCESS no ambiente',
                'Verifica os usuários que possuem permissões a nível de servidor "XU" (UNSAFE ASSEMBLY) e "XA" (EXTERNAL ACCESS ASSEMBLY)',
                'Remova essas permissões caso esses usuários não precisem fazer deploy de assemblies SQLCLR nesses 2 modos de segurança',
                'http://www.sqlservercentral.com/articles/Stairway+Series/112888/',
                NULL
            ),
            (
                410, 
                'Permissões',
                'Permissões em Extended Procedures (xp_%)', 
                NULL, 
                'Permissão que possibilita que um determinado login possa utilizar Extended Procedures na instância, que são comandos que podem ler/gravar informações do registro do Windows, além de várias outras tarefas que podem causar risco para o ambiente',
                'Verifica os usuários que possuem permissões em objetos de sistema que comecem com xp_%',
                'Remova essas permissões',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-06-16/finding/V-2473',
                NULL
            ),
            (
                500, 
                'Vulnerabilidades em Código',
                'Objetos com IMPERSONATE', 
                NULL, 
                'Verificação de procura por objetos (Stored Procedures, Functions, etc) que são executados como outro usuário que não o executor da Procedure',
                'Verifica no código-fonte de todos os objetos, de todos os databases, os que objetos que são executados com as permissões de um usuário fixo (IMPERSONATE)',
                'Remova o comando "EXECUTE AS" da declaração desses objetos, caso não seja necessário',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                501, 
                'Vulnerabilidades em Código',
                'Objetos com Query Dinâmica', 
                NULL, 
                'Verificação de procura por objetos (Stored Procedures, Functions, etc) que possuem execução de códigos com query dinâmica, permitindo ataques como SQL Injection em suas aplicações e execução de códigos maliciosos',
                'Verifica no código-fonte de todos os objetos, de todos os databases, os que objetos que utilizam query dinâmica e que são o provável motivo dessa configuração estar habilitada',
                'Remova o uso de query dinâmica sempre que possível. Quando não for possível, valide o uso da query dinâmica para garantir que os parâmetros de entrada estão sendo tratados e que não são vulneráveis a ataques de SQL Injection',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-sql-injection-pare-de-utilizar-query-dinamica-como-execquery-agora/',
                NULL
            ),
            (
                502, 
                'Vulnerabilidades em Código',
                'Objetos utilizando xp_cmdshell', 
                NULL, 
                'Verificação de procura por objetos (Stored Procedures, Functions, etc) que possuem execução de códigos utilizando xp_cmdshell, permitindo que um usuário com acesso à essa SP possa executar qualquer comando que o usuário do serviço do SQL Server tenha acesso',
                'Verifica no código-fonte de todos os objetos, de todos os databases, os que objetos que utilizam xp_cmdshell e que são o provável motivo dessa configuração estar habilitada',
                'Remova o uso de comandos xp_cmdshell. Ao invés dele, opte por SQLCLR ou pacotes do SSIS',
                'https://hydrasky.com/network-security/mssql-server-injection-tutorial/',
                NULL
            ),
            (
                503, 
                'Vulnerabilidades em Código',
                'Objetos utilizando OLE Automation', 
                NULL, 
                'Verificação de procura por objetos (Stored Procedures, Functions, etc) que possuem execução de códigos utilizando OLE Automation Procedures, que são conhecidas por possíveis memory dumps, vazamentos de memória e acessos externos diversos, como escrever arquivos, enviar requisições HTTP, etc.',
                'Verifica no código-fonte de todos os objetos, de todos os databases, os que objetos que utilizam OLE Automation e que são o provável motivo dessa configuração estar habilitada',
                'Remova o uso de comandos OLE Automation. Ao invés dele, opte por SQLCLR ou pacotes do SSIS',
                'https://visualstudiomagazine.com/articles/2005/09/01/when-to-use-sqlclr-and-when-not-to.aspx',
                NULL
            ),
            (
                504, 
                'Vulnerabilidades em Código',
                'Procedures Executadas Automaticamente', 
                NULL, 
                'Verificação de procura por objetos que são executados automaticamente na inicialização do SQL Server, o que pode ser utilizado por invasores para executar códigos maliciosos toda vez que o serviço for iniciado',
                'Verifica na DMV sys.procedures de todos os databases, quais procedures possuem a propriedade is_auto_executed = 1',
                'Remova essas SPs da inicialização do SQL Server utilizando a SP sp_procoption ou dropando e recriando essa SP',
                'http://blogs.lessthandot.com/index.php/datamgmt/datadesign/list-all-stored-procedures-that/',
                NULL
            ),
            (
                505, 
                'Vulnerabilidades em Código',
                'Objetos utilizando GRANT', 
                NULL, 
                'Verificação de procura por objetos (Stored Procedures, Functions, etc) que possuem execução de códigos utilizando comandos de GRANT, liberando permissões que podem ser perigosas no ambiente, especialmente se estiver dentro de jobs e rotinas automáticas',
                'Verifica no código-fonte de todos os objetos, de todos os databases, os que objetos que utilizam comandos de GRANT para liberar permissões',
                'Remova o uso de comandos GRANT de objetos',
                NULL,
                NULL
            ),
            (
                506, 
                'Vulnerabilidades em Código',
                'Linked Server com usuário Fixo', 
                NULL, 
                'Verificação de procura por Linked Servers que utilizam um usuário fixo ao invés do usuário atual',
                'Verifica nas DMVs sys.servers e sys.linked_logins se existe Linked Server com usuário fixo (uses_self_credential = 0)',
                'Se possível, troque a autenticação do Linked Server pelo usuário atual da conexão',
                NULL,
                NULL
            ),
            (
                600, 
                'Instalação',
                'Porta Padrão (1433)', 
                NULL, 
                'Essa verificação valida se o SQL Server está utilizando a porta padrão (1433) para conexões. Utilizar a porta padrão pode significar um risco de segurança, pois é a primeira porta que qualquer hacker tentaria invadir num possível ataque',
                'Verifica se o SQL Server está utilizando a porta padrão (1433) para conexões',
                'Altere a porta do SQL Server para algum porta diferente do padrão, a fim de prover mais uma camada de segurança, dificultando ataques hackers',
                'https://thomaslarock.com/2016/12/using-non-default-ports-for-sql-server/',
                NULL
            ),
            (
                601, 
                'Instalação',
                'SQL Browser executando com apenas 1 instância', 
                NULL, 
                'Essa configuração valida se o SQL Browser está sendo executado em ambientes com apenas 1 instância, o que não justifica a execução desse serviço, que serve para fornecer informações das instâncias instaladas no servidor e pode facilitar ataques maliciosos ao expor os nomes das instâncias na rede. Caso essa instância não faça parte de um cluster, analise se o serviço pode ser desativado e se portas customizadas estão sendo utilizadas.',
                'Verifica se o SQL Browser está sendo executado em ambientes com apenas 1 instância',
                'Desabilite o SQL Browser caso você esteja utilizando a instância padrão do SQL Server OU se na string de conexão você já utiliza o formato "SERVIDOR\INSTANCIA,PORTA"',
                'https://www.stigviewer.com/stig/ms_sql_server_2014_instance/2016-11-16/finding/V-70623',
                NULL
            ),
            (
                602, 
                'Instalação',
                'Nome da instância exposta na rede', 
                NULL, 
                'Essa configuração valida se o nome da instância está exposta na rede, permitindo que ela seja listada através da opção "Browse.." do SQL Server Management Studio (SSMS)',
                'Verifica se o parâmetro HideInstance está ativado no SQL Configuration Manager',
                'Ative o parâmetro "Hide Instance" dessa instância no SQL Configuration Manager, abaixo de "SQL Server Network Configuration" -> "Protocols for <Sua Instancia>"',
                'https://www.mytechmantra.com/LearnSQLServer/How_to_Hide_an_Instance_of_SQL_Server.html',
                NULL
            ),
            (
                603, 
                'Instalação',
                'Usuário dos Serviços de SQL',
                NULL, 
                'Essa configuração valida os usuários utilizados para iniciar os serviços do SQL Server. A recomendação é que sejam utilizados usuários do AD, para que a manutenção desses usuários seja fácil pelo time de Infra. Usuários locais não devem ser utilizados, pois ele possuem permissões elevadas nos diretórios do SO',
                'Verifica se os usuários utilizados pelos serviços são os usuários padrão do SQL Server',
                'Altere o usuário dos serviços SQL por usuários do AD, com permissões restritas, caso seu servidor precise de acesso à rede ou a outros servidores. Caso contrário, utilize a conta Local User Account',
                'https://sqlcommunity.com/best-practices-for-sql-server-service-account/',
                NULL
            ),
            (
                604, 
                'Instalação',
                'SQL Server em Windows com versão antiga ou pessoal', 
                NULL, 
                'Essa configuração valida se o SQL Server está instalado em uma versão desatualizada do Windows Server ou se está instalado numa versão pessoal do Windows',
                'Verifica a versão do Windows para identificar se está utilizando a versão mais recente do Windows Server',
                'Utilize sempre a versão mais recente do Windows Server para garantir a utilização de novas recursos e correções de segurança',
                'https://www.microsoft.com/pt-br/cloud-platform/windows-server',
                NULL
            ),
            (
                605, 
                'Instalação',
                'Versão do SQL Server não suportada',
                NULL, 
                'Essa configuração valida se o SQL Server possui uma versão que ainda tem suporte e atualizações pela Microsoft',
                'Verifica a versão do SQL Server ainda é suportada pela Microsoft',
                'Atualize a versão do SQL Server para receber atualizações de segurança e utilizar novos recursos',
                'https://www.microsoft.com/pt-br/sql-server/sql-server-downloads',
                NULL
            ),
            (
                606, 
                'Instalação',
                'SQL Server desatualizado', 
                NULL, 
                'Essa configuração valida se o SQL Server está instalado com a última versão dos Service Pack e Cumulative Updates disponíveis. Estar sempre atualizado é importante para a segurança, pois garante que falhas críticas estejam sempre atualizadas e corrigidas',
                'Verifica se o build mais recente do SQL Server é o mesmo do build instalado',
                'Utilize sempre a versão mais recente SQL Server e o mantenha atualizado com a última versão do Service Pack e Cumulative Updates',
                NULL,
                NULL
            ),
            (
                607, 
                'Instalação',
                'Databases públicas instaladas', 
                NULL, 
                'Essa configuração valida se algum dos databases públicos são instalados na instância, servindo como uma possível porta de entrada para ataques, já que sua estrutura é amplamente conhecida',
                'Verifica se os databases pub, Northwind, AdventureWorks, AdventureWorksLT, AdventureWorksDW, WideWorldImporters ou WideWorldImportersDW estão instalados',
                'Caso seja uma base de produção, remova esses databases e crie-os em instâncias de testes/desenvolvimento',
                'https://www.stigviewer.com/stig/ms_sql_server_2014_instance/2017-11-30/finding/V-67817',
                NULL
            ),
            (
                608, 
                'Instalação',
                'Protocolos de rede não necessários', 
                NULL, 
                'Essa configuração valida quais os protocolos de rede sendo utilizados na instância. Por padrão, o protocolo TCP/IP é o único necessário, enquanto o Shared Memory é indicado para conexões feita no próprio servidor, e o Named Pipes é uma conexão que deve ser utilizada quando ocorrem problemas no TCP/IP',
                'Verifica se quais os protocolos de rede utilizados na sys.dm_exec_connections',
                'Desative os protocolos de rede que não são estritamente necessários, como o VIVA, Named Pipes e Shared Memory',
                'https://blogs.msdn.microsoft.com/securesql/2018/03/the-sql-server-defensive-dozen-part-1-hardening-sql-network-components/',
                NULL
            ),
            (
                609, 
                'Instalação',
                'Windows Firewall desativado', 
                NULL, 
                'Essa configuração valida se o Firewall do Windows está ativado no servidor',
                'Verifica no registro do Windows se o Firewall está ativo',
                'Verifique se existe outro software de Firewall no servidor. Caso não tenha, ative o Firewall do Windows',
                NULL,
                NULL
            )
        
    END
    ELSE IF (@language = 'en')
    BEGIN
        
        INSERT INTO #Resultado
        (
            Id_Verificacao,
            Ds_Categoria,
            Ds_Titulo,
            Ds_Resultado,
            Ds_Descricao,
            Ds_Verificacao,
            Ds_Sugestao,
            Ds_Referencia,
            Ds_Detalhes
        )
        VALUES
            (-8, 'Information', 'Copyright', 'Info', 'stpSecurity_Checklist 1.0', NULL, NULL, NULL, '<Details><Copyright>Stored Procedure developed by Dirceu Resende</Copyright><Website>https://www.dirceuresende.com</Website></Details>'),
            (-7, 'Information', 'Version', 'Info', @@VERSION, NULL, NULL, NULL, NULL),
            (-6, 'Information', 'Server info', 'Info', NULL, NULL, NULL, NULL, NULL),
            (-5, 'Information', 'Startup time', 'Info', NULL, NULL, NULL, NULL, NULL),
            (-4, 'Information', 'Startup parameters', 'Info', 'Checks SQL Server startup parameters in use by this instance', NULL, NULL, NULL, NULL),
            (-3, 'Information', 'Instances on the server', 'Info', NULL, NULL, NULL, NULL, NULL),
            (-2, 'Information', 'Instance is part of a Cluster', 'Info', (CASE WHEN CAST(SERVERPROPERTY('IsClustered') AS VARCHAR(10)) = '1' THEN 'YES' ELSE 'NO' END), NULL, NULL, NULL, NULL),
            (-1, 'Information', 'Help', 'Info', 'Did you find an issue in your SQL Server instance and need our help to fix it? Get in touch and protect your instance(s) with an Expert team', NULL, NULL, NULL, '<Contacts><Whatsapp>https://bit.ly/dirceuresende</Whatsapp><Telegram>https://t.me/dirceuresende</Telegram><Skype>@dirceuresende</Skype><Email>contato@fabriciolima.net</Email></Contacts>'),
            (0, '----------------------', '----------------------', '----------------------', '----------------------', NULL, NULL, NULL, NULL),
            (
                1, 
                'Configurations',
                'Trustworthy', 
                NULL, 
                'Configuration that allows you to execute malicious commands inside the database and "take control" of other databases by users who are in db_owner role',
                'Checks if any database has the "TRUSTWORTHY" property enabled',
                'Disable the "TRUSTWORTHY" property of all databases. If you use SQLCLR assemblies, use encryption keys instead of "Trustworthy"',
                'https://docs.microsoft.com/en-us/sql/relational-databases/security/trustworthy-database-property?view=sql-server-2017',
                NULL
            ),
            (
                2, 
                'Configurations',
                'Login Failure Audit', 
                NULL, 
                'Configuration that allows auditing of login failures in the instance when users miss the password. This setting is recommended to be enabled to be able to identify possible brute-force attacks on the instance', 
                'Checks whether the instance is writing to the log when the user misses a password',
                'Enable connection auditing for login failures',
                'https://www.mssqltips.com/sqlservertip/1735/auditing-failed-logins-in-sql-server/',
                NULL
            ),
            (
                3, 
                'Configurations',
                'Windows Authentication Only',
                NULL, 
                'Configuration that allows authentication using Windows Integrated Security (more secure), but also SQL Server authentication, using user and password (less secure). This configuration is not exactly a problem because there are legacy applications that require SQL Server authentication, but it is a good practice to avoid this scenario when possible.',
                'Checks whether the instance accepts connections using SQL Server authentication',
                'Disable SQL Server login authentication when possible',
                'https://docs.microsoft.com/en-us/sql/relational-databases/security/choose-an-authentication-mode?view=sql-server-2017',
                NULL
            ),
            (
                4, 
                'Configurations',
                'Ad hoc distributed queries', 
                NULL, 
                'Configuration that allows to execute commands remotely through OPENROWSET / OPENDATASOURCE. The possible security issue caused by this configuration is allow a compromised server accessing data from another server or even a compromised server sending back information during hacker attacks',
                'Checks whether the "Ad hoc distributed queries" setting is enabled in sp_configure',
                'Disable the "Ad hoc distributed queries" configuration if you are not using OPENROWSET / OPENDATASOURCE and neither SQL Server 2005',
                'https://cuttingedge.it/blogs/steven/pivot/entry.php?id=44',
                NULL
            ),
            (
                5, 
                'Configurations',
                'cross db ownership chaining', 
                NULL, 
                'A configuration that allows a person to access objects that they do not have access in another database through specific scenarios of "cross db ownership chaining"',
                'Checks whether the "cross db ownership chaining" setting is active in sp_configure',
                'Disable the "cross db ownership chaining" setting if you are not using this feature (its not a very common scenario)',
                'http://www.sqlservercentral.com/articles/Stairway+Series/123545/',
                NULL
            ),
            (
                6, 
                'Configurations',
                'SQL Server / Windows Updates', 
                NULL, 
                'This validation identifies when the instance startup date is more than 60 days old, indicating that Windows and SQL Server updates are not being applied',
                'Checks the SQL Server service startup date',
                'Apply Windows updates as well as SQL Server Service Packs and Cumulative Updates. Many updates are patches, hotfixes and security packages',
                'https://sqlserverbuilds.blogspot.com/',
                NULL
            ),
            (
                7, 
                'Configurations',
                'Databases without page verification', 
                NULL, 
                'Configuration that allows SQL Server to write a CHECKSUM on each page as it goes into storage, and then check CHECKSUM again when the data is read from the disk to try to ensure data integrity. This may generate a small CPU overhead, but it is usually worth because it helps detecting corruption',
                'Checks if any database is using some page validation algorithm other than CHECKSUM (NONE or TORN_PAGE)',
                'Change the page validation algorithm for all databases to CHECKSUM',
                'https://www.brentozar.com/blitz/page-verification/',
                NULL
            ),
            (
                8, 
                'Configurations',
                'Default trace enabled', 
                NULL,
                'Configuration that allows SQL Server to collect some information about the instance using Default Trace, like DDL and DCL commands.',
                'Checks whether the default SQL Server trace is enabled and running',
                'Enable the default SQL Server trace to audit events',
                'https://www.dirceuresende.com/blog/utilizando-o-trace-padrao-do-sql-server-para-auditar-eventos-fn_trace_gettable/',
                NULL
            ),
            (
                9, 
                'Configurations',
                'scan for startup procs', 
                NULL,
                'A configuration that allows a person to monitor which objects are executed at SQL Server startup and to create malicious code on those objects.',
                'Checks whether the "scan for startup procs" setting is enabled on the instance using sp_configure',
                'Disable this setting if you are not performing any validation of what runs during SQL Server startup',
                'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-scan-for-startup-procs-server-configuration-option?view=sql-server-2017',
                NULL
            ),
            (
                10, 
                'Configurations',
                'DatabaseMail XPs', 
                NULL,
                'Configuration that allows a person to send email and any information from the databases to others using DatabaseMail. Although this is widely used by systems and alerts, you should verify that this is really necessary in the instance and is being used. If not, disable this option.',
                'Checks whether the "Database Mail XPs" setting is enabled in sp_configure',
                'Disable this setting if you do not have any routine that sends emails through the database and cannot be sent using SSIS, for example',
                'https://www.sqlshack.com/securing-sql-server-surface-area/',
                NULL
            ),
            (
                11, 
                'Configurations',
                'SQL Mail XP', 
                NULL,
                'A configuration that allows a person to send email and any information from the databases to others using SQL Mail XP (available through SQL Server 2012. After that, it has been replaced by DatabaseMail). Although this is widely used by systems and alerts, you should verify that this is really necessary in the instance and is being used. If not, disable this option.',
                'Checks whether the "SQL Mail XP" setting is enabled in sp_configure',
                'Disable this setting if you do not have any routine that sends emails through the database and cannot be sent using SSIS, for example',
                'https://www.sqlshack.com/securing-sql-server-surface-area/',
                NULL
            ),
            (
                12, 
                'Configurations',
                'Remote Admin Connections (DAC)', 
                NULL,
                'A configuration that allows administrator users (sysadmin) to log on to the instance even when it is experiencing a problem that prevents logon or when the instance connection limit is reached. This configuration must be enabled so that it can be used in an emergency',
                'Checks whether the "remote admin connections" setting is enabled in sp_configure',
                'Enable the "remote admin connections" setting in sp_configure',
                'https://www.dirceuresende.com/blog/habilitando-e-utilizando-a-conexao-remota-dedicada-para-administrador-dac-no-sql-server/',
                NULL
            ),
            (
                13, 
                'Configurations',
                'Remote Access', 
                NULL,
                'Configuration that allows users to run Stored Procedures remotely through Linked Server, allowing a hacker to use a compromised instance to perform DDoS attacks on another instance of the network. This parameter is marked as Deprecated and if it is not used by any routine, it should be disabled.',
                'Checks whether the "remote access" setting is enabled in sp_configure',
                'Disable the "remote access" setting if you do not use Stored Procedures remotely by using Linked Servers',
                'https://docs.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-remote-access-server-configuration-option?view=sql-server-2017',
                NULL
            ),
            (
                14, 
                'Configurations',
                'SMO and DMO XPs', 
                NULL,
                'Configuration that allows users to code in SQL Server using programming languages like C#, VB, and PowerShell. If it''s not being used, it''s best practice to disable this feature. Note: If you are using SSMS to access SQL Server, you may need to enable this parameter to be able to use SSMS',
                'Checks whether the "SMO and DMO XPs" setting is enabled in sp_configure',
                'Disable the "SMO and DMO XPs" setting if you do not use SMO programming',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-04-03/finding/V-15211',
                NULL
            ),
            (
                15, 
                'Configurations',
                'Server Trigger Enabled', 
                NULL, 
                'This configuration validates whether any server-level triggers are enabled in the instance. This feature can be used by hackers to prevent certain users from logging on or spy users information',
                'Checks if a server-level trigger is enabled on the instance',
                'Validate if this server trigger is correct and does not influence any risk to users',
                NULL,
                NULL
            ),
            (
                16, 
                'Configurations',
                'Trace Enabled',
                NULL, 
                'This setting validates whether any trace is enabled in the instance. This feature allows you to analyze and capture information from queries executed in the database. This can be used for auditing purposes, but also could be used to capture sensitive data by malicious people',
                'Checks if any trace (other than the default trace) is enabled on the instance',
                'Validate if this trace was actually created by the DBA team and does not influence any risk to users',
                NULL,
                NULL
            ),
            (
                17, 
                'Configurations',
                'Extended Events (XE) Enabled',
                NULL, 
                'This setting validates whether any extended event (XE) is enabled in the instance. This feature allows you to analyze and capture information from queries executed in the database. This can be used for auditing purposes, but also could be used to capture sensitive data by malicious people',
                'Checks if any Extended Event (other than SQL Server defaults) is enabled on the instance',
                'Validate if this XE was actually created by the DBA team and does not influence any risk to users',
                NULL,
                NULL
            ),
			(
                18, 
                'Configurations',
                'Auto Close disabled for Contained Databases',
                NULL, 
                'Because authentication of users for contained databases occurs within the database not at the server\instance level, the database must be opened every time to authenticate a user. The frequent opening/closing of the database consumes additional server resources and may contribute to a denial of service.',
                'Checks if any contained databases has AUTO_CLOSE enabled',
                'This setting should be disabled to stop frequent opening and closing of databases connections',
                'https://docs.microsoft.com/en-us/sql/relational-databases/databases/security-best-practices-with-contained-databases?view=sql-server-2017',
                NULL
            ),
			(
                19, 
                'Configurations',
                'Low number of Error Logs retained',
                NULL, 
                'SQL Server	error log files must be protected from loss.',
                'The log files must be backed up before they are overwritten. Frequently a SQL Server is restarted multiple times to try and solve a problem. This causes the error log to recycle and you lose important troubleshooting information. This is a scored item from the Center for Internet Security (CIS).',
                'Adjust the number of logs to prevent data loss. The default value of 6 maybe insufficient for a production environment. ',
                'https://www.brentozar.com/archive/2015/09/forgotten-maintenance-cycling-the-sql-server-error-log/',
                NULL
            ),
            (
                100, 
                'User Security',
                'User/password failure', 
                NULL, 
                'Checks how many login attempts failed due to incorrect username and password',
                'Checks in the SQL Server log for incorrect password login failure events',
                'Check the source of these connections and if you don''t know them, block the IP in Firewall. A good suggestion is to periodically change the password of SQL users and use strong passwords to prevent intrusions',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-ataques-de-forca-bruta-no-seu-banco-de-dados/',
                NULL
            ),
            (
                101, 
                'User Security',
                'SA Login', 
                NULL, 
                'Default SQL Server user who has the highest possible permission (sysadmin). Must be disabled and renamed to avoid possible hacker attacks',
                'Checks if login "sa" is enabled',
                'Disable the login "sa" and change it''s name',
                'https://www.dirceuresende.com/blog/sql-server-como-desativar-o-login-sa-minimizando-impactos/',
                NULL
            ),
            (
                102, 
                'User Security',
                'Orphan Users', 
                NULL, 
                'Users who do not have associated logins. Probably some mapping error. These users must be removed or remapped with their login. This type of situation can be used by hackers to try to access databases that these users have privileges. Also, orphaned users raise the complexity of managing logins security, because there are more users than necessary',
                'Checks users created in databases and does not have associated logins on the instance',
                'Try again the remapping with sp_change_users_login. If login does not actually exist, try to analyze whether this user can be removed',
                'https://www.dirceuresende.com/blog/identificando-e-resolvendo-problemas-de-usuarios-orfaos-no-sql-server-com-a-sp_change_users_login/',
                NULL
            ),
            (
                103, 
                'User Security',
                'Users without password change policy', 
                NULL, 
                'SQL Server logins that don''t have a password policy, which means that the password does not expire and/or has no complexity requirements defined. If the user is used by an application, this alert can be ignored, but if it''s a regular user login, it should be forced to change the password regularly and have complex passwords',
                'Checks logins that don''t have password expiration options and/or are not compliance with password policies',
                'Enable the "enforce password policy" and "enforce password expiration" options in the login properties screen',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017',
                NULL
            ),
            (
                104, 
                'User Security',
                'Users with old password', 
                NULL, 
                'SQL Server logins that the password doesn''t expire and has not been changed for more than 180 days. Even though if it''s a user used by an application, its password must be changed regularly to avoid possible hacker attacks',
                'Checks if the SQL Server login password has not been changed for more than 180 days',
                'Change the password for all SQL Server logins regularly to prevent password leaks',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/password-policy?view=sql-server-2017',
                NULL
            ),
            (
                105, 
                'User Security',
                'Users with weak passwords', 
                NULL, 
                'SQL Server logins that have weak passwords that were easily broken using this Stored Procedure',
                'It tries to break the SQL logins password using the PWDCOMPARE function and a small base of more common passwords',
                'Regularly change your SQL logins password and use strong and complex passwords to make brute force attacks more difficult',
                'https://www.dirceuresende.com/blog/sql-server-como-identificar-senhas-frageis-vazias-ou-iguais-ao-nome-do-usuario/',
                NULL
            ),
            (
                106, 
                'User Security',
                'Users without permissions', 
                NULL, 
                'Users who do not have any permissions in the database, which means that they were created in the database but shouldn''t have no need anymore. These users can probably be safely deleted from the database to reduce the number of users/logins.',
                'Identifies database users who are not in any role and do not have any permissions on the database',
                'Consider whether these users can be removed',
                NULL,
                NULL
            ),
            (
                107, 
                'User Security',
                'AD users without using Kerberos', 
                NULL, 
                'Identifies whether the NTLM authentication protocol is being used instead of Kerberos, which is a more secure server-to-server and Double-Hop enable protocol',
                'Identifies users with AD authentication in sys.dm_exec_connections who are not using Kerberos',
                'Analyze whether the instance''s SPN is configured correctly in AD records',
                'https://www.dirceuresende.com/blog/sql-server-autenticacao-ad-kerberos-ntlm-login-failed-for-user-nt-authorityanonymous-logon/',
                NULL
            ),
            (
                108, 
                'User Security',
                'VIEW ANY DATABASE Permission', 
                NULL, 
                'Identifies if there are any users with VIEW ANY DATABASE permissions, allowing them to see the name of all instance databases',
                'Analyze in DMV sys.server_permissions if any user with SQL authentication has VIEW ANY DATABASE permission',
                'Remove the VIEW ANY DATABASE permission from the default public role and all users who do not access SQL Server through SSMS, especially systems. Using the AD Domain\Domain Users group may be a safer alternative to public',
                'https://www.dirceuresende.com/blog/sql-server-como-ocultar-os-databases-para-usuarios-nao-autorizados/',
                NULL
            ),
			(
                109, 
                'User Security',
                'Windows BUILTIN Groups', 
                NULL, 
                'By default this group has SQL Server System Administrator rights to SQL Server when it is installed.  The same level of default rights are also granted to BUILTIN\Administrators group in SQL Server 2005 during the installation.',
                'The BUILTIN groups	(Administrators, Everyone, Authenticated Users,	Guests,	etc.) generally contain very broad memberships which would not meet	the	best practice of ensuring only the necessary users have been granted access to a SQL Server instance. These groups should not be used for any level of access into a SQL Server Database Engine instance.',
                'The BUILTIN in groups can easily be removed from SQL Server to prevent this security issue, but before you should create a more restrictive AD group containing only required user accounts',
                'https://www.mssqltips.com/sqlservertip/1017/security-issues-with-the-sql-server-builtin-administrators-group/',
                NULL
            ),
			(
                110, 
                'User Security',
                'Windows Local Groups', 
                NULL, 
                'Local	Windows	groups	should	not	be	used	as	logins	for	SQL	Server	instances.',
                'Allowing local Windows groups as SQL Logins provides a loophole whereby anyone with OS level administrator rights (and no SQL Server rights) could add users to the local Windows groups and thereby give themselves or others access to the SQL Server instance.',
                'The local Windows in groups can easily be removed from SQL Server to prevent this security issue, but before you should create a more restrictive AD group containing only required user accounts.',
                NULL,
                NULL
            ),
            (
                200, 
                'Programming',
                'xp_cmdshell', 
                NULL, 
                'Configuration that allows to execute malicious commands inside the database using xp_cmdshell',
                'Verify that the "xp_cmdshell" setting is enabled in sp_configure',
                'Disable this setting if you are not using it in any routine. If so, try to use another solution, such as SQLCLR or SSIS, to provide this functionality',
                'http://www.sqlservercentral.com/blogs/brian_kelley/2009/11/13/why-we-recommend-against-xp-cmdshell/',
                NULL
            ),
            (
                201, 
                'Programming',
                'Ole Automation', 
                NULL, 
                'Configuration that allows to execute malicious commands within the database using OLE Automation procedures',
                'Verify that the "Ole Automation Procedures" setting is enabled in sp_configure',
                'Disable this setting if you are not using it in any routine. If so, try to use another solution, such as SQLCLR or SSIS, to provide this functionality',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-04-03/finding/V-2472',
                NULL
            ),
            (
                202, 
                'Programming',
                'SQLCLR', 
                NULL, 
                'Configuration that allows to execute malicious commands inside the database using SQLCLR procedures',
                'Checks whether the "clr enabled" setting is enabled in sp_configure',
                'Disable the "clr enabled" setting if you are not using any SQLCLR libraries',
                'https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-2017',
                NULL
            ),
            (
                203, 
                'Programming',
                'SQLCLR Unsafe/External Access', 
                NULL, 
                'Configuration that allows to execute malicious commands within the database using SQLCLR procedures with Unsafe/External Access permission',
                'Checks if any assembly, from any database, was created with PERMISSION_SET = UNSAFE or EXTERNAL_ACCESS',
                'Validate if this library is actually being used and sign the assembly using encryption certificate',
                'https://docs.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-2017',
                NULL
            ),
            (
                204, 
                'Programming',
                'External Scripts (R, Python, or Java)', 
                NULL, 
                'Configuration that allows to execute malicious commands inside the database using scripts in R (SQL 2016), Python (SQL 2017) or Java (SQL 2019)',
                'Checks whether the "external scripts enabled" setting is enabled in sp_configure',
                'Disable the "external scripts enabled" configuration if you don''t use Python, R, or Java in SQL Server',
                'https://www.stigviewer.com/stig/ms_sql_server_2016_instance/2018-03-09/finding/V-79347',
                NULL
            ),
            (
                300, 
                'Data Security',
                'Transparent Data Encryption (TDE)', 
                NULL, 
                'Configuration that allows you to encrypt data files, backups and logs to avoid unauthorized access to data',
                'Validate databases that do not have TDE enabled',
                'Enable TDE on SQL Server 2008+ databases to automatically encrypt data files, logs, and backups',
                'https://www.dirceuresende.com/blog/sql-server-2008-como-criptografar-seus-dados-utilizando-transparent-data-encryption-tde/',
                NULL
            ),
            (
                301, 
                'Data Security',
                'Databases without Backup', 
                NULL, 
                'Validation that identifies databases with NO BACKUP, which can cause a tragedy if any data becomes corrupted or the database was attacked by a ransomware',
                'Checks databases that do not have any type of backup in the past 7 days',
                'Create automatic routines for FULL + DIFF + LOG backup in production environment or FULL daily backup for non-critical environments',
                'https://edvaldocastro.com/politicabkp/',
                NULL
            ),
            (
                302, 
                'Data Security',
                'Backups without Encryption', 
                NULL, 
                'Validation that identifies databases without encrypted backups, which allows third parties to be able to read data if they can access the backup files',
                'Scans for non-encrypted database backups',
                'Implement TDE on the database or change your backup routine to encrypt backups',
                'https://www.tiagoneves.net/blog/criando-um-backup-criptografado-no-sql-server/',
                NULL
            ),
            (
                303, 
                'Data Security',
                'Recovery Model FULL without LOG Backup', 
                NULL, 
                'Validation that identifies databases with recovery model set to FULL, but no log backup routine configured, which is probably an incorrect configuration or lack of backup routine',
                'Checks databases with FULL recovery model, but no log backup routine',
                'Implement an automatic log backup routine or change the Recovery Model to SIMPLE if it''s not a critical environment and some data after the last full backup could be lost in case of failure',
                'https://www.brentozar.com/blitz/full-recovery-mode-without-log-backups/',
                NULL
            ),
            (
                304, 
                'Data Security',
                'Database files extension',
                NULL, 
                'This setting validates whether SQL Server is using the default extensions for data files, logs, and backups, which are targets of Ransomwares, such WannaCry',
                'Checks whether SQL Server databases are using the default extension for data files (MDF) and logs (LDF)',
                'Use custom extensions for data files, logs, and backups, making it difficult for viruses and ransonwares to attack SQL Server database files',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
                NULL
            ),
            (
                305, 
                'Data Security',
                'Backup files extension',
                NULL, 
                'This setting validates whether SQL Server is using the default extensions for the database backup file, which are targets of Ransomwares, such WannaCry',
                'Checks whether SQL Server databases are using the default extensions for backup files (BAK)',
                'Use custom extensions for backups files, making it difficult for viruses and ransonwares to attack SQL Server backup files',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
                NULL
            ),
            (
                306, 
                'Data Security',
                'Backup Storage',
                NULL, 
                'This setting validates whether SQL Server is configured to use another backup destination, different that just the disk',
                'Checks whether SQL Server databases are using workarounds for storing backup files such as cloud and/or tape',
                'Use more than one location to store your SQL Server backup files, because if you store only in one physical location, you can lose all data in a disaster',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-e-se-proteger-de-ataques-de-ransomware-como-wannacry-no-seu-servidor-de-banco-de-dados/',
                NULL
            ),
            (
                400, 
                'Permissions',
                'CONTROL SERVER Permission', 
                NULL, 
                'Elevated permission that allows you to control almost everything and even shut down the SQL Server instance',
                'Checks users with CONTROL SERVER permission or elevated permissions on the instance',
                'Remove the elevated permissions of these users if they are not DBAs and the permissions are not really necessary and justifiable',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2012_database_instance/2017-04-03/finding/V-41268',
                NULL
            ),
            (
                401, 
                'Permissions',
                'Users in the sysadmin/securityadmin roles', 
                NULL, 
                'Elevated permission that allows you to do anything on the instance, including execute commands like another login, control and even, shut down the instance SQL Server',
                'Checks the users who are on the sysadmin and/or securityadmin server roles',
                'Remove these users from these two roles if they are not DBAs and it''s not really necessary and justifiable for these users to be in those roles',
                'https://renatomsiqueira.com/category/security/roles-security/',
                NULL
            ),
            (
                402, 
                'Permissions',
                'IMPERSONATE ANY LOGIN', 
                NULL, 
                'Permission that allows a given login to execute commands as ANY USER, including a sysadmin user and become sysadmin himself',
                'Verifies users who have the "IMPERSONATE ANY LOGIN" permission on the instance',
                'Remove this permission from these users',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                403, 
                'Permissions',
                'IMPERSONATE LOGIN', 
                NULL, 
                'Permission that allows a given login to execute commands as another login. This can be an issue to audit routines, identifying the wrong user (impersonated login instead of original login).',
                'Checks users who have the "IMPERSONATE LOGIN" permission on the instance',
                'Remove this permission from users unless there is some plausible reason why a login should have permission to run commands like another login',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                404, 
                'Permissions',
                'IMPERSONATE LOGIN on sysadmin/securityadmin logins', 
                NULL, 
                'Permission that allows a given login to execute commands as another login with elevated permissions (securityadmin / sysadmin / CONTROL SERVER / IMPERSONATE ANY LOGIN)',
                'Identifies users with "IMPERSONATE LOGIN" privilege on user accounts that are sysadmin / security admin or have elevated privileges',
                'Remove this IMPERSONATE LOGIN "permission from these users',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                405, 
                'Permissions',
                'db_owner and db_securityadmin', 
                NULL, 
                'Permission that allows a given user to perform any action in a specific database. If the database has the trustworthy option enabled, a user in db_owner role can become a sysadmin using elevation of privilege attack',
                'Checks in all databases, who are the users in the roles db_owner and db_securityadmin',
                'Remove these users from these database roles and analyze how to replace them, such as a db_ddladmin, for example, or another role with even fewer permissions',
                'https://docs.microsoft.com/pt-br/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-2017',
                NULL
            ),
            (
                406, 
                'Permissions',
                'IMPERSONATE USER', 
                NULL, 
                'Permission that allows a given user to perform actions as if it were another user',
                'Checks in all the databases which are the users that have permission of "IMPERSONATE USER"',
                'Remove this permission from users if there is no reason for a user to execute commands in the database as if it were someone else',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                407, 
                'Permissions',
                'PUBLIC role with permissions', 
                NULL, 
                'Validation that ensures that the PUBLIC role does not have any high permission on the instance, since all users of the instance are on that role automatically. All permissions that this role has, can be used by ANY user of the instance.',
                'Checks in all databases and in the instance, all the permissions that the PUBLIC role has',
                'Remove all permissions from public role',
                'https://basitaalishan.com/2013/04/04/the-public-role-do-not-use-it-for-database-access/',
                NULL
            ),
            (
                408, 
                'Permissions',
                'GUEST user with permissions', 
                NULL, 
                'Validation that ensures that the GUEST user has no permission on the instance. This special user allows access to any login that does not have user mapped in a database and therefore, must have the privilege of CONNECT revoked in all databases (except from msdb, master e tempdb)',
                'Checks whether the GUEST user has any permissions on the instance (except from CONNECT permission in msdb, master and tempdb databases)',
                'Remove all permissions from the GUEST user other than CONNECT on the msdb, master, and tempdb databases',
                'https://basitaalishan.com/2012/08/28/sql-server-guest-user-still-a-serious-security-threat/',
                NULL
            ),
            (
                409, 
                'Permissions',
                'Users with UNSAFE/EXTERNAL ASSEMBLY permissions', 
                NULL, 
                'Permission that allows a particular login to create SQLCLR assemblies with UNSAFE/EXTERNAL ACCESS security mode in the environment',
                'Verifies users who have server-level permissions "XU" (UNSAFE ASSEMBLY) and "XA" (EXTERNAL ACCESS ASSEMBLY)',
                'Remove these permissions if these users do not need to deploy SQLCLR assemblies in these 2 security modes',
                'http://www.sqlservercentral.com/articles/Stairway+Series/112888/',
                NULL
            ),
            (
                410, 
                'Permissions',
                'Extended Procedures (xp_%) permissions', 
                NULL, 
                'Permission that allows a given login to use Extended Procedures on the instance, which are commands that can read/write information in the Windows registry, as well as various other tasks that may pose a risk to the environment',
                'Checks users who have permissions on system objects that start with xp_%',
                'Remove these permissions',
                'https://www.stigviewer.com/stig/microsoft_sql_server_2005_instance/2015-06-16/finding/V-2473',
                NULL
            ),
            (
                500, 
                'Code Vulnerabilities',
                'Objects with IMPERSONATE', 
                NULL, 
                'Scans for database objects (Stored Procedures, Functions, etc.) that run as another user other than the caller of the procedure',
                'Checks in the source code of all objects, in all databases, which objects that are executed with the permissions of a fixed user (IMPERSONATE)',
                'Remove the "EXECUTE AS" command from the declaration of these objects, if it''s not really necessary',
                'https://www.dirceuresende.com/blog/sql-server-como-utilizar-o-execute-as-para-executar-comandos-como-outro-usuario-impersonate-e-como-impedir-isso/',
                NULL
            ),
            (
                501, 
                'Code Vulnerabilities',
                'Objects with Dynamic Query', 
                NULL, 
                'Scans for database objects (Stored Procedures, Functions, etc) that have dynamic query in its code, allowing attacks like SQL Injection in your applications and execution of malicious code',
                'Checks in the source code of all objects, in all databases, which objects that use dynamic query and could be used by attacks',
                'Remove the use of dynamic query whenever possible. When this is not possible, validate the use of the dynamic query to ensure that the input parameters are being handled and are not vulnerable to SQL Injection attacks',
                'https://www.dirceuresende.com/blog/sql-server-como-evitar-sql-injection-pare-de-utilizar-query-dinamica-como-execquery-agora/',
                NULL
            ),
            (
                502, 
                'Code Vulnerabilities',
                'Objects using xp_cmdshell', 
                NULL, 
                'Scans for database objects (Stored Procedures, Functions, etc.) that have xp_cmdshell in its code, allowing a user with access to this SP to execute any command that the SQL Server service user has access to',
                'Checks in the source code of all objects, in all databases, which objects that use xp_cmdshell and could be used by attacks',
                'Remove the use of xp_cmdshell commands. Instead, choose SQLCLR or SSIS packages',
                'https://hydrasky.com/network-security/mssql-server-injection-tutorial/',
                NULL
            ),
            (
                503, 
                'Code Vulnerabilities',
                'Objects using OLE Automation', 
                NULL, 
                'Scans for database objects (Stored Procedures, Functions, etc.) that use OLE Automation Procedures, which are known for possible memory dumps, memory leaks and various external accesses, such as writing files, sending HTTP requests, etc.',
                'Checks in the source code of all objects, all databases, which objects that use OLE Automation and could be used by attacks',
                'Remove OLE Automation commands from any object. Instead, choose SQLCLR or SSIS packages',
                'https://visualstudiomagazine.com/articles/2005/09/01/when-to-use-sqlclr-and-when-not-to.aspx',
                NULL
            ),
            (
                504, 
                'Code Vulnerabilities',
                'Startup Procedures', 
                NULL, 
                'Check for objects that run automatically on SQL Server startup, which can be used by attackers to execute malicious code every time the service starts',
                'Checks in DMV sys.procedures of all databases, which procedures have the property is_auto_executed = 1',
                'Remove these SPs from SQL Server startup by using SP sp_procoption or by dropping and recreating this SP',
                'http://blogs.lessthandot.com/index.php/datamgmt/datadesign/list-all-stored-procedures-that/',
                NULL
            ),
            (
                505, 
                'Code Vulnerabilities',
                'Objects using GRANT commands', 
                NULL, 
                'Scans for database objects (Stored Procedures, Functions, etc) that have GRANT commands in its code. This can be dangerous in the environment, especially if it''s inside jobs and automatic routines, because it can be part of an attack ou a malicious code or pearson',
                'Checks in the source code of all objects, in all databases, which objects that use GRANT commands',
                'Remove the GRANT commands from these objects',
                NULL,
                NULL
            ),
            (
                506, 
                'Code Vulnerabilities',
                'Linked Server with Fixed User', 
                NULL, 
                'Validation that checks for Linked Servers that use a fixed user in the connection, instead of the current user',
                'Checks in the sys.servers and sys.linked_logins DMVs if there is a Linked Server with a fixed user (uses_self_credential = 0)',
                'If possible, change the authentication of the Linked Server to use the current user of the connection',
                NULL,
                NULL
            ),
            (
                600, 
                'Installation',
                'Default Port (1433)', 
                NULL, 
                'This check validates whether SQL Server is using the default port (1433) for connections. Using the default port can pose a security risk as it''s the first port that any attacker would attempt to hack in a possible attack',
                'Verifies that SQL Server is using the default port (1433) for connections',
                'Change the SQL Server port to some port other than the default, in order to provide one more layer of security, making it a little more complex for attacks',
                'https://thomaslarock.com/2016/12/using-non-default-ports-for-sql-server/',
                NULL
            ),
            (
                601, 
                'Installation',
                'SQL Browser running with only 1 instance on server', 
                NULL, 
                'This setting validates whether SQL Browser is running in a server with only 1 instance, which does not justify running this service. SQL Browser goal is to provide information about instances installed on the server, but to do that, it can expose the names of instances on the network, which makes a possible attack easier. If this instance is not part of a cluster, consider whether the service can be disabled and whether custom ports are being used.',
                'Checks whether the SQL browser is running in servers with only 1 instance',
                'Disable SQL Browser if you are using the default instance of SQL Server OR if in the connection string you already use the format "SERVER\INSTANCE, PORT"',
                'https://www.stigviewer.com/stig/ms_sql_server_2014_instance/2016-11-16/finding/V-70623',
                NULL
            ),
            (
                602, 
                'Installation',
                'Instance name exposed on the network', 
                NULL, 
                'This setting validates if the instance name is exposed on the network, allowing it to be listed through the "Browse .." option in SQL Server Management Studio (SSMS)',
                'Verifies if the "HideInstance" parameter is enabled in SQL Configuration Manager',
                'Enable the "Hide Instance" parameter for this instance in SQL Configuration Manager under "SQL Server Network Configuration" -> "Protocols for <Your Instance>"',
                'https://www.mytechmantra.com/LearnSQLServer/How_to_Hide_an_Instance_of_SQL_Server.html',
                NULL
            ),
            (
                603, 
                'Installation',
                'SQL Services User',
                NULL, 
                'This setting validates the users used to start the SQL Server services. The recommendation is that AD users are used, so that the maintenance of these users is easier for the Infra team. Local users should not be used because they have elevated permissions on OS directories',
                'Verifies that the users used by the services are the default SQL Server users',
                'Change the SQL services user by AD users, with restricted permissions, if your server needs access to the network or other servers. Otherwise, use the Local User Account',
                'https://sqlcommunity.com/best-practices-for-sql-server-service-account/',
                NULL
            ),
            (
                604, 
                'Installation',
                'SQL Server on Windows with old or personal version', 
                NULL, 
                'This setting validates whether SQL Server is installed on an outdated version of Windows Server or whether it is installed on a personal version of Windows',
                'Checks the version of Windows to identify whether you are using the latest version of Windows Server',
                'Always use the latest version of Windows Server to ensure the use of new features and security fixes',
                'https://www.microsoft.com/pt-br/cloud-platform/windows-server',
                NULL
            ),
            (
                605, 
                'Installation',
                'Unsupported version of SQL Server',
                NULL, 
                'This setting validates whether SQL Server has a version that is still supported and updated by Microsoft',
                'Checks the version of SQL Server is still supported by Microsoft',
                'Upgrade the version of SQL Server to receive security updates and use new features',
                'https://www.microsoft.com/pt-br/sql-server/sql-server-downloads',
                NULL
            ),
            (
                606, 
                'Installation',
                'Outdated SQL Server', 
                NULL, 
                'This setting validates whether SQL Server is installed with the latest version of Service Pack and Cumulative Updates available. Keeping up-to-date is important for security as it ensures that critical failures are always up-to-date and fixed',
                'Checks if the latest SQL Server build is the same as the build installed',
                'Always use the latest SQL Server version and keep it up to date with the latest Service Pack and Cumulative Updates',
                NULL,
                NULL
            ),
            (
                607, 
                'Installation',
                'Public Databases Installed', 
                NULL, 
                'This setting validates if any of the public databases are installed on the instance, serving as a possible gateway to attacks, as their structure is widely known',
                'Checks whether the pubs, Northwind, AdventureWorks, AdventureWorksLT, AdventureWorksDW, WideWorldImporters, or WideWorldImportersDW databases are installed',
                'If it is a production base, remove these databases and create them in test/development instances',
                'https://www.stigviewer.com/stig/ms_sql_server_2014_instance/2017-11-30/finding/V-67817',
                NULL
            ),
            (
                608, 
                'Installation',
                'Network protocols not required', 
                NULL, 
                'This setting validates which network protocols are being used in the instance. By default, the TCP/IP and Shared Memory protocols are the only one required and Named Pipes is a connection that should be used when TCP / IP problems occur',
                'Checks which network protocols are used in sys.dm_exec_connections',
                'Disable network protocols that are not strictly required, such as VIVA and Named Pipes',
                'https://blogs.msdn.microsoft.com/securesql/2018/03/the-sql-server-defensive-dozen-part-1-hardening-sql-network-components/',
                NULL
            ),
            (
                609, 
                'Installation',
                'Windows Firewall disabled', 
                NULL, 
                'This setting validates whether Windows Firewall is enabled on the server.',
                'Checks the Windows registry if Firewall is active',
                'Check if there is another Firewall software on the server. If you do not have it, enable Windows Firewall',
                NULL,
                NULL
            )
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Informações de inicialização
    ---------------------------------------------------------------------------------------------------------------

    SET @Data = (SELECT sqlserver_start_time FROM sys.dm_os_sys_info)
    
    DECLARE @PortaUtilizada INT = (SELECT TOP(1) local_tcp_port FROM sys.dm_exec_connections WHERE local_tcp_port IS NOT NULL ORDER BY session_id)


    IF (@language = 'pt')
    BEGIN
    
        UPDATE #Resultado
        SET Ds_Descricao = 'ComputerNamePhysicalNetBIOS: ' + COALESCE(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(500)), '') + ' | Nome do servidor: ' + COALESCE(CAST(SERVERPROPERTY('MachineName') AS VARCHAR(500)), '') + ' | Instância: ' + COALESCE(ISNULL(CAST(SERVERPROPERTY('InstanceName') AS VARCHAR(500)), 'MSSQLSERVER'), '') + ' | Porta: ' + COALESCE(CAST(@PortaUtilizada AS VARCHAR(20)), '1433')
        WHERE Id_Verificacao = -6

        UPDATE #Resultado
        SET Ds_Descricao = CONVERT(VARCHAR(10), @Data, 103) + ' ' + CONVERT(VARCHAR(10), @Data, 108) + ' (' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @Data, GETDATE())) + ' dias atrás)'
        WHERE Id_Verificacao = -5
        
    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET Ds_Descricao = 'ComputerNamePhysicalNetBIOS: ' + COALESCE(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS VARCHAR(500)), '') + ' | Server name: ' + COALESCE(CAST(SERVERPROPERTY('MachineName') AS VARCHAR(500)), '') + ' | Instance name: ' + COALESCE(ISNULL(CAST(SERVERPROPERTY('InstanceName') AS VARCHAR(500)), 'MSSQLSERVER'), '') + ' | Port: ' + COALESCE(CAST(@PortaUtilizada AS VARCHAR(20)), '1433')
        WHERE Id_Verificacao = -6

        UPDATE #Resultado
        SET Ds_Descricao = CONVERT(VARCHAR(10), @Data, 103) + ' ' + CONVERT(VARCHAR(10), @Data, 108) + ' (' + CONVERT(VARCHAR(10), DATEDIFF(DAY, @Data, GETDATE())) + ' days ago)'
        WHERE Id_Verificacao = -5
        
    END



    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE
            @RegHive VARCHAR(50),
            @RegKey VARCHAR(100)

        SET @RegHive = 'HKEY_LOCAL_MACHINE'
        SET @RegKey = 'Software\Microsoft\MSSQLSERVER\MSSQLServer\Parameters'

        DECLARE @SQLArgs TABLE
        (
            [Value] VARCHAR(50),
            [Data] VARCHAR(500),
            ArgNum AS CONVERT(INTEGER, REPLACE(Value, 'SQLArg', ''))
        )

        INSERT INTO @SQLArgs
        EXECUTE master.sys.xp_instance_regenumvalues @RegHive, @RegKey

    

        SET @Resultado = NULL

        SET @Resultado = (
            SELECT *
            FROM @SQLArgs
            FOR XML PATH, ROOT('Parametros_Inicializacao')
        )


        DECLARE @GetInstances TABLE ( 
            [Value] nvarchar(100),
            InstanceNames nvarchar(100),
            [Data] nvarchar(100)
        )

        INSERT INTO @GetInstances
        EXECUTE master.dbo.xp_regread
            @rootkey = 'HKEY_LOCAL_MACHINE',
            @key = 'SOFTWARE\Microsoft\Microsoft SQL Server',
            @value_name = 'InstalledInstances'


        DECLARE 
            @Instancias VARCHAR(MAX),
            @Qt_Instancias INT = (SELECT COUNT(*) FROM @GetInstances)
    
        SET @Instancias = ''

        SELECT 
            @Instancias += (CASE WHEN @Instancias = '' THEN '' ELSE '; ' END) + A.InstanceNames
        FROM
            @GetInstances A



        IF (@language = 'pt')
        BEGIN
    
            UPDATE #Resultado
            SET Ds_Descricao = CAST(@Qt_Instancias AS VARCHAR(10)) + ' instâncias instaladas: ' + @Instancias
            WHERE Id_Verificacao = -3

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET Ds_Descricao = CAST(@Qt_Instancias AS VARCHAR(10)) + ' SQL Server instances on this server: ' + @Instancias
            WHERE Id_Verificacao = -3
            
        END


        UPDATE #Resultado
        SET Ds_Detalhes = (CASE 
            WHEN @language = 'en' THEN REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Parametros_Inicializacao>', 'Startup_Parameters>')
            ELSE @Resultado
        END)
        WHERE 
            Id_Verificacao = -4


    END
    ELSE BEGIN
        
        DELETE FROM #Resultado
        WHERE Id_Verificacao IN (-3, -4)

    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o banco está como TRUSTWORTHY
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name] 
        FROM 
            sys.databases 
        WHERE 
            is_trustworthy_on = 1 
            AND [name] <> 'msdb' 
        FOR XML PATH, ROOT('Databases')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 1

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 1
        
    END

    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a instância está auditando falhas de login
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @AuditLevel INT

    EXEC master.dbo.xp_instance_regread
        @rootkey = 'HKEY_LOCAL_MACHINE',
        @key = 'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer',
        @value_name = 'AuditLevel',
        @value = @AuditLevel OUTPUT


    SET @Resultado = NULL

    IF (@AuditLevel < 2)
    BEGIN

        SET @Resultado = (
            SELECT 
                (CASE @AuditLevel
                    WHEN 0 THEN '0 - Nenhum'
                    WHEN 1 THEN '1 - Apenas logins com sucesso'
                    ELSE NULL
                END) AS Nivel_Auditoria_Login
            FOR XML PATH, ROOT('Nivel_Auditoria')
        )

    END
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 2

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Nivel_Auditoria>', 'AuditLevel>'), '0 - Nenhum', '0 - None'), '1 - Apenas logins com sucesso', '1 - Successful logins only')
        WHERE 
            Id_Verificacao = 2
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a instância está permitindo logins SQL Server
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Quantidade = CONVERT(INT, SERVERPROPERTY('IsIntegratedSecurityOnly'))
    
    
    SET @Resultado = NULL

    IF (@Quantidade = 0)
    BEGIN

        SET @Resultado = (
            SELECT 
                (CASE @Quantidade  
                    WHEN 0 THEN '0 - Autenticação Windows e SQL Server'
                    ELSE NULL
                END) AS Nivel_Auditoria_Login
            FOR XML PATH, ROOT('Nivel_Auditoria_Login')
        )

    END
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 3

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Nivel_Auditoria_Login>', 'Login_Audit_Level>'), '0 - Autenticação Windows e SQL Server', '0 - Windows and SQL Server Authentication')
        WHERE 
            Id_Verificacao = 3
        
    END

        
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado "Ad hoc distributed queries"
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'Ad hoc distributed queries'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 4

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 4
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado "cross db ownership chaining"
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'cross db ownership chaining'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 5

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 5
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a máquina não está aplicando Windows Updates
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL
    SET @Quantidade = (SELECT DATEDIFF(DAY, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info)

    IF (@Quantidade > 60)
    BEGIN

        SET @Resultado = (
            SELECT 
                sqlserver_start_time 
            FROM 
                sys.dm_os_sys_info WITH(NOLOCK)
            FOR XML PATH, ROOT('Inicialização')
        )

    END
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado (pelo menos ' + CONVERT(VARCHAR(10), @Quantidade) + ' dias sem atualização)' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 6

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found (at least ' + CONVERT(VARCHAR(10), @Quantidade) + ' days without updates)' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Inicialização>', 'Startup>')
        WHERE 
            Id_Verificacao = 6
        
    END

    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica databases sem verificação de página
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name] AS 'Database/@name',
            page_verify_option_desc AS 'Database/@page_verify_option_desc',
            create_date AS 'Database/@create_date',
            [compatibility_level] AS 'Database/@compatibility_level',
            collation_name AS 'Database/@collation_name',
            user_access_desc AS 'Database/@user_access_desc',
            state_desc AS 'Database/@state_desc',
            recovery_model_desc AS 'Database/@recovery_model_desc'
        FROM 
            sys.databases WITH(NOLOCK) 
        WHERE
            page_verify_option <> 2 -- CHECKSUM
            AND [state] = 0 -- ONLINE
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Configuracao'), TYPE
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 7

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 7
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o default trace está ativado
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            *
        FROM 
            sys.traces WITH(NOLOCK) 
        WHERE 
            is_default = 1
            AND [status] = 0
        FOR XML PATH, ROOT('Configuracao')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 8

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 8
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado "scan for startup procs"
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'scan for startup procs'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 9

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 9
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado o DatabaseMail
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'Database Mail XPs'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 10

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 10
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado o SQL Mail XP (antigo DatabaseMail)
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK)
        WHERE 
            [name] = 'SQL Mail XP'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 11

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 11
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado o Remote Admin Connections (DAC)
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'remote admin connections'
            AND value_in_use = 0
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 12

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 12
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado o Remote Connections
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'remote access'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 13

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 13
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se está habilitado SMO and DMO XPs
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [name]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'SMO and DMO XPs'
            AND value_in_use = 0
        FOR XML PATH, ROOT('Configuracao')
    )
    
    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 14

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 14
        
    END


    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existe alguma trigger a nível de servidor
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT DISTINCT 
            A.[name] AS 'Trigger/@trigger_name', 
            B.event_group_type_desc AS 'Trigger/@event_group_type_desc'
        FROM 
            sys.server_triggers A WITH(NOLOCK)
            JOIN sys.server_trigger_events B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
        WHERE
            A.is_ms_shipped = 0
            AND A.is_disabled = 0
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Configuracao_Server_Triggers'), TYPE
    )

    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 15

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao_Server_Triggers>', 'Server_Triggers>')
        WHERE 
            Id_Verificacao = 15
        
    END

        
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existe algum trace habilitado no servidor
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            id AS 'Trace/@id',
            [status] AS 'Trace/@status',
            [path] AS 'Trace/@path',
            max_size AS 'Trace/@max_size',
            stop_time AS 'Trace/@stop_time',
            max_files AS 'Trace/@max_files',
            is_rowset AS 'Trace/@is_rowset',
            is_rollover AS 'Trace/@is_rollover',
            is_shutdown AS 'Trace/@is_shutdown',
            is_default AS 'Trace/@is_default',
            buffer_count AS 'Trace/@buffer_count',
            buffer_size AS 'Trace/@buffer_size',
            file_position AS 'Trace/@file_position',
            reader_spid AS 'Trace/@reader_spid',
            start_time AS 'Trace/@start_time',
            last_event_time AS 'Trace/@last_event_time',
            event_count AS 'Trace/@event_count',
            dropped_event_count AS 'Trace/@dropped_event_count'
        FROM
            sys.traces WITH(NOLOCK)
        WHERE
            is_default = 0
            AND [status] = 1
            AND [path] NOT LIKE '%Traces\Duracao.trc'
        FOR XML PATH(''), ROOT('Configuracao_Trace_Habilitado'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 16

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao_Trace_Habilitado>', 'Trace_Enabled>')
        WHERE 
            Id_Verificacao = 16
        
    END

        

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existe algum Extended Event (XE) habilitado no servidor
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.event_session_id AS 'Extended_Event/@event_session_id',
            A.[name] AS 'Extended_Event/@name',
            B.create_time AS 'Extended_Event/@create_time',
            C.target_name AS 'Extended_Event/@target_name',
            C.execution_count AS 'Extended_Event/@execution_count',
            C.execution_duration_ms AS 'Extended_Event/@execution_duration_ms',
            A.event_retention_mode_desc AS 'Extended_Event/@event_retention_mode_desc',
            CAST(C.target_data AS VARCHAR(MAX)) AS 'Extended_Event/@targetdata'
        FROM
            sys.server_event_sessions AS A WITH(NOLOCK) 
            LEFT JOIN sys.dm_xe_sessions AS B WITH(NOLOCK) ON A.[name] = B.[name]
            LEFT JOIN sys.dm_xe_session_targets AS C WITH(NOLOCK) ON C.event_session_address = B.[address]
        WHERE
            A.[name] NOT IN ( 'system_health', 'StretchDatabase_Health', 'telemetry_xevents', 'hkenginexesession', 'sp_server_diagnostics session', 'AlwaysOn_health', 'QuickSessionStandard', 'QuickSessionTSQL' )
        ORDER BY
            2
        FOR XML PATH(''), ROOT('Configuracao_XE_Habilitado'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 17

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao_XE_Habilitado>', 'Extended_Event_Enabled>')
        WHERE 
            Id_Verificacao = 17
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verify 'AUTO_CLOSE' is set to 'OFF' on contained 
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
			name AS 'Contained/@name',
			containment AS 'Contained/@containment', 
			containment_desc AS 'Contained/@contaiment_type', 
			is_auto_close_on AS 'Contained/@auto_close'
		FROM 
			sys.databases
		WHERE 
			containment <> 0 
			AND is_auto_close_on <> 0
		FOR XML PATH(''), ROOT('Configuracao_AC_Habilitado'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 18

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao_AC_Habilitado>', 'Contained_AC_Enabled>')
        WHERE 
            Id_Verificacao = 18
        
    END

	---------------------------------------------------------------------------------------------------------------
    -- Verify Max Number Error Log's are greater than the default
    ---------------------------------------------------------------------------------------------------------------
    
	SET @Resultado = NULL
	DECLARE @NumErrorLogs int;
	DECLARE @ErrorLog int;

	EXEC master.sys.xp_instance_regread N'HKEY_LOCAL_MACHINE',N'Software\Microsoft\MSSQLServer\MSSQLServer',N'NumErrorLogs',@NumErrorLogs OUTPUT;

	SET @ErrorLog = (SELECT CASE WHEN @NumErrorLogs >=12 THEN NULL ELSE 1 END)
	SET @NumErrorLogs = CASE WHEN @ErrorLog IS NULL THEN NULL ELSE @NumErrorLogs END

    SET @Resultado = (
        SELECT @ErrorLog AS 'ErrorLogs/@ErrorLog'
			,@NumErrorLogs AS 'ErrorLogs/@NumberOfLogFiles'
		ORDER BY 1
		FOR XML PATH(''), ROOT('Configuracao_EL_Habilitado'), TYPE
    )

	SET @Resultado = (SELECT CASE WHEN CAST(@Resultado AS VARCHAR(MAX)) = '<Configuracao_EL_Habilitado/>' THEN NULL ELSE @Resultado END)

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 19

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao_EL_Habilitado>', 'Error_Log>')
        WHERE 
            Id_Verificacao = 19
        
    END

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem erros no log de falha de login
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Login_Failed TABLE ( [LogDate] datetime, [ProcessInfo] nvarchar(12), [Text] nvarchar(3999) )
    
    INSERT INTO @Login_Failed
    EXEC master.dbo.sp_readerrorlog 0, 1, 'Password did not match that for the login provided' 

    SET @Resultado = NULL
    
    SET @Resultado = (
        SELECT 
            LogDate AS 'Log/@Date',
            [Text] AS 'Log/@Mensagem'
        FROM 
            @Login_Failed
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Erro_Login_Senha_Incorreta'), TYPE
    )


    SELECT @Quantidade = COUNT(*) FROM @Login_Failed


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado (' + CAST(@Quantidade AS VARCHAR(10)) + ' tentativas)' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 100

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found (' + CAST(@Quantidade AS VARCHAR(10)) + ' attempts)' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Erro_Login_Senha_Incorreta>', 'Wrong_Username_Password>')
        WHERE 
            Id_Verificacao = 100
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Usuário "SA" habilitado
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS [login],
            A.principal_id,
            A.[sid],
            A.[type_desc],
            A.is_disabled,
            A.create_date,
            A.modify_date
        FROM
            sys.server_principals A WITH(NOLOCK)
        WHERE
            A.principal_id = 1 -- sa
            AND A.is_disabled = 0
        FOR XML PATH, ROOT('Usuario_SA_Habilitado')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 101

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuario_SA_Habilitado>', 'SA_User_Enabled>')
        WHERE 
            Id_Verificacao = 101
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Usuários órfãos
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Usuarios_Orfaos TABLE ( Ds_Database VARCHAR(256), Ds_Usuario VARCHAR(256) )

    SET @Query = '
SELECT
    ''?'' AS [database_name],
    [name] AS [user]
FROM
    [?].sys.database_principals WITH(NOLOCK)
WHERE
    [sid] NOT IN
    (
        SELECT
            [sid]
        FROM
            [?].sys.server_principals WITH(NOLOCK)
    )
    ' + (CASE WHEN @Versao > 2008 THEN 'AND authentication_type_desc = ''INSTANCE''' ELSE '' END) + '
    AND [type] = ''S''
    AND principal_id > 4
    AND DATALENGTH([sid]) <= 28
    AND [name] <> ''MS_DataCollectorInternalUser''
    AND [name] NOT LIKE ''##MS_%'''


    INSERT INTO @Usuarios_Orfaos (Ds_Database, Ds_Usuario)
    EXEC master.dbo.sp_MSforeachdb @Query


    SELECT @Quantidade = COUNT(*)
    FROM @Usuarios_Orfaos


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Usuario/@database',
            Ds_Usuario AS 'Usuario/@usuario'
        FROM 
            @Usuarios_Orfaos
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Usuarios_Orfaos'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado (' + CAST(@Quantidade AS VARCHAR(10)) + ' usuários)' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 102

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found (' + CAST(@Quantidade AS VARCHAR(10)) + ' users)' END),
            Ds_Detalhes = REPLACE(REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Orfaos>', 'Orphaned_Users>'), '<Usuario ', '<User '), 'usuario=', 'user=')
        WHERE 
            Id_Verificacao = 102
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Usuários sem políticas de troca de senha
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @UsuariosPoliticaSenha TABLE ( [login] nvarchar(128), [principal_id] int, [sid] varbinary(85), [type_desc] nvarchar(60), [is_policy_checked] bit, [is_expiration_checked] bit, [DaysUntilExpiration] INT, [PasswordLastSetTime] DATETIME, [IsExpired] BIT, [IsMustChange] BIT )

    INSERT INTO @UsuariosPoliticaSenha
    SELECT 
        A.[name] AS [login],
        A.principal_id,
        A.[sid],
        A.[type_desc],
        B.is_policy_checked,
        B.is_expiration_checked,
        CONVERT(INT, LOGINPROPERTY(B.[name], 'DaysUntilExpiration')) DaysUntilExpiration,
        CONVERT(DATETIME, LOGINPROPERTY(B.[name], 'PasswordLastSetTime')) PasswordLastSetTime,
        CONVERT(BIT, LOGINPROPERTY(B.[name], 'IsExpired')) IsExpired,
        CONVERT(BIT, LOGINPROPERTY(B.[name], 'IsMustChange')) IsMustChange
    FROM
        sys.server_principals A WITH(NOLOCK)
        JOIN sys.sql_logins B WITH(NOLOCK) ON B.[sid] = A.[sid]
    WHERE
        A.is_disabled = 0
        AND A.principal_id > 10


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [login] AS 'Usuario/@login',
            principal_id AS 'Usuario/@principal_id',
            is_policy_checked AS 'Usuario/@is_policy_checked',
            is_expiration_checked AS 'Usuario/@is_expiration_checked',
            DaysUntilExpiration AS 'Usuario/@DaysUntilExpiration',
            PasswordLastSetTime AS 'Usuario/@PasswordLastSetTime',
            IsExpired AS 'Usuario/@IsExpired',
            IsMustChange AS 'Usuario/@IsMustChange'
        FROM
            @UsuariosPoliticaSenha
        WHERE
            is_policy_checked = 0 
            OR is_expiration_checked = 0
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Sem_Politica_de_Senha'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 103

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Sem_Politica_de_Senha>', 'Users_Without_Password_Policy>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 103
        
    END


    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [login] AS 'Usuario/@login',
            PasswordLastSetTime AS 'Usuario/@PasswordLastSetTime',
            principal_id AS 'Usuario/@principal_id',
            is_policy_checked AS 'Usuario/@is_policy_checked',
            is_expiration_checked AS 'Usuario/@is_expiration_checked',
            DaysUntilExpiration AS 'Usuario/@DaysUntilExpiration',
            IsExpired AS 'Usuario/@IsExpired',
            IsMustChange AS 'Usuario/@IsMustChange'
        FROM
            @UsuariosPoliticaSenha
        WHERE
            is_expiration_checked = 0
            AND DaysUntilExpiration IS NULL
            AND DATEDIFF(DAY, PasswordLastSetTime, GETDATE()) > 180
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Senha_Antiga'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 104

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Senha_Antiga>', 'Users_Old_Password>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 104
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com senhas fracas
    ---------------------------------------------------------------------------------------------------------------

    DECLARE 
        @Contador INT, 
        @Total INT, 
        @Contador2 INT, 
        @Total2 INT, 
        @Atual VARCHAR(100)

    SELECT
        @Contador = 1,
        @Total = 10,
        @Contador2 = 1,
        @Total2 = 10,
        @Atual = ''
    
    DECLARE @Senhas TABLE ( Senha VARCHAR(100) )
    DECLARE @Usuarios_Senha_Fraca TABLE ( [Login] nvarchar(256), is_disabled BIT, is_policy_checked BIT, [Senha] NVARCHAR(200) )


    INSERT INTO @Senhas
    VALUES 
        ('teste'), ('TESTE'), ('password'), ('qwerty'),
        ('football'), ('baseball'), ('welcome'), ('abc123'),
        ('1qaz2wsx'), ('dragon'), ('master'), ('monkey'), ('letmein'),
        ('login'), ('princess'), ('qwertyuiop'), ('solo'), ('passw0rd'), 
        ('starwars'), ('teste123'), ('TESTE123'), ('deuseamor'), ('jesuscristo'),
        ('iloveyou'), ('MARCELO'), ('jc2512'), ('maria'), ('jose'), ('batman'),
        ('123123'), ('123123123'), ('FaMiLia'), (''), (' '), ('sexy'),
        ('abel123'), ('freedom'), ('whatever'), ('qazwsx'), ('trustno1'), ('sucesso'),
        ('1q2w3e4r'), ('1qaz2wsx'), ('1qazxsw2'), ('zaq12wsx'), ('! qaz2wsx'),
        ('!qaz2wsx'), ('123mudar'), ('gabriel'), ('102030'), ('010203'), ('101010'), ('131313'),
        ('vitoria'), ('flamengo'), ('felipe'), ('brasil'), ('felicidade'), ('mariana'), ('101010')
    

    -- Números repetidos
    WHILE(@Contador < @Total)
    BEGIN
    
        WHILE(@Contador2 < @Total2)
        BEGIN
        
            INSERT INTO @Senhas
            SELECT REPLICATE(CAST(@Contador AS VARCHAR(100)), @Contador2)

            SET @Contador2 += 1

        END

        SET @Contador += 1
        SET @Contador2 = 1

    END


    SET @Contador = 12
    SET @Contador2 = 1

    -- Letras repetidos
    WHILE(@Contador < 126)
    BEGIN
    
        WHILE(@Contador2 < @Total2)
        BEGIN
        
            INSERT INTO @Senhas
            SELECT REPLICATE(CHAR(@Contador), @Contador2)

            SET @Contador2 += 1

        END

        SET @Contador += 1
        SET @Contador2 = 1

    END


    -- Sequências
    SET @Contador = 0

    WHILE(@Contador <= @Total)
    BEGIN
    
        SET @Atual = @Atual + CAST((CASE WHEN @Contador = 10 THEN 0 ELSE @Contador END) AS VARCHAR(100))

        INSERT INTO @Senhas
        SELECT @Atual
    
        SET @Contador = @Contador + 1
    
    END


    SET @Contador = 1
    SET @Atual = ''

    WHILE(@Contador <= @Total)
    BEGIN
    
        SET @Atual = @Atual + CAST((CASE WHEN @Contador = 10 THEN 0 ELSE @Contador END) AS VARCHAR(100))

        INSERT INTO @Senhas
        SELECT @Atual
    
        SET @Contador = @Contador + 1
    
    END


    -- Logins
    INSERT INTO @Senhas
    SELECT [name]
    FROM sys.sql_logins WITH(NOLOCK)

    INSERT INTO @Senhas
    SELECT LOWER([name])
    FROM sys.sql_logins WITH(NOLOCK)

    INSERT INTO @Senhas
    SELECT UPPER([name])
    FROM sys.sql_logins WITH(NOLOCK)

    INSERT INTO @Senhas
    SELECT DISTINCT REVERSE(Senha)
    FROM @Senhas

    
    INSERT INTO @Usuarios_Senha_Fraca
    SELECT
        A.[name],
        A.is_disabled,
        A.is_policy_checked,
        B.Senha
    FROM 
        sys.sql_logins		    A WITH(NOLOCK)
        CROSS APPLY @Senhas		B
    WHERE
        PWDCOMPARE(B.Senha, A.password_hash) = 1

   

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT DISTINCT
            [Login] AS 'Login/@name',
            Senha AS 'Login/@password',
            is_disabled AS 'Login/@is_disabled',
            is_policy_checked AS 'Login/@is_policy_checked'
        FROM
            @Usuarios_Senha_Fraca
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Senha_Fraca'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 105

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Senha_Fraca>', 'Users_Weak_Password>')
        WHERE 
            Id_Verificacao = 105
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Usuários sem Permissão
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Usuarios_Sem_Permissao TABLE ( [database_name] nvarchar(128), [name] nvarchar(128), [principal_id] int, [type_desc] nvarchar(60), [default_schema_name] nvarchar(128), [create_date] datetime, [modify_date] datetime )

    
    INSERT INTO @Usuarios_Sem_Permissao
    EXEC master.dbo.sp_MSforeachdb 'SELECT
    ''?'' AS [database_name],
    A.[name],
    A.principal_id,
    A.[type_desc],
    A.default_schema_name,
    A.create_date,
    A.modify_date
FROM
    [?].sys.database_principals A WITH(NOLOCK)
    LEFT JOIN [?].sys.database_role_members B WITH(NOLOCK) ON A.principal_id = B.member_principal_id
    LEFT JOIN [?].sys.database_permissions C WITH(NOLOCK) ON A.principal_id = C.grantee_principal_id
WHERE
    B.member_principal_id IS NULL
    AND C.grantee_principal_id IS NULL
    AND A.is_fixed_role = 0
    AND A.principal_id > 4'

    

    SELECT @Quantidade = COUNT(*)
    FROM @Usuarios_Sem_Permissao


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database_name] AS 'Usuario/@database',
            [name] AS 'Usuario/@name',
            principal_id AS 'Usuario/@principal_id',
            [type_desc] AS 'Usuario/@type_desc',
            default_schema_name AS 'Usuario/@default_schema_name',
            create_date AS 'Usuario/@create_date',
            modify_date AS 'Usuario/@modify_date'
        FROM 
            @Usuarios_Sem_Permissao
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Usuarios_Sem_Permissao'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado (' + CAST(@Quantidade AS VARCHAR(10)) + ' usuários)' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 106

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found (' + CAST(@Quantidade AS VARCHAR(10)) + ' users)' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Sem_Permissao>', 'Users_Without_Permissions>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 106
        
    END
    

    ---------------------------------------------------------------------------------------------------------------
    -- Usuários utilizando autenticação AD sem utilizar o protocolo de autenticação Kerberos
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE
        @Qt_NTLM INT, @Qt_Kerberos INT

    SELECT
        @Qt_NTLM = SUM(CASE WHEN A.auth_scheme = 'NTLM' THEN 1 ELSE 0 END),
        @Qt_Kerberos = SUM(CASE WHEN A.auth_scheme = 'Kerberos' THEN 1 ELSE 0 END)
    FROM 
        sys.dm_exec_connections A
        JOIN sys.dm_exec_sessions B ON B.session_id = A.session_id
        JOIN sys.server_principals C ON B.original_security_id = C.[sid]
    WHERE
        C.[type_desc] = 'WINDOWS_LOGIN'
        AND C.principal_id > 10
        AND B.nt_domain NOT LIKE 'NT Service%'
        

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.session_id AS 'Sessao/@session_id',
            B.login_name AS 'Sessao/@login_name',
            B.nt_domain AS 'Sessao/@nt_domain',
            B.nt_user_name AS 'Sessao/@nt_user_name',
            A.net_transport AS 'Sessao/@net_transport',
            A.auth_scheme AS 'Sessao/@auth_scheme',
            B.[host_name] AS 'Sessao/@host_name',
            B.[program_name] AS 'Sessao/@program_name',
            A.connect_time AS 'Sessao/@connect_time',
            A.encrypt_option AS 'Sessao/@encrypt_option'
        FROM 
            sys.dm_exec_connections A
            JOIN sys.dm_exec_sessions B ON B.session_id = A.session_id
            JOIN sys.server_principals C ON B.original_security_id = C.[sid]
        WHERE
            C.[type_desc] = 'WINDOWS_LOGIN'
            AND C.principal_id > 10
            AND B.nt_domain NOT LIKE 'NT Service%'
            AND A.auth_scheme <> 'Kerberos'
        ORDER BY
            2
        FOR XML PATH(''), ROOT('Usuarios_AD_Sem_Kerberos'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN ISNULL(@Qt_Kerberos, 0) >= ISNULL(@Qt_NTLM, 0) THEN 'OK' ELSE 'Possível problema encontrado (' + CAST(ISNULL(@Qt_NTLM, 0) AS VARCHAR(10)) + ' conexões NTLM)' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 107

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN ISNULL(@Qt_Kerberos, 0) >= ISNULL(@Qt_NTLM, 0) THEN 'OK' ELSE 'Possible issue found (' + CAST(ISNULL(@Qt_NTLM, 0) AS VARCHAR(10)) + ' NTLM connections)' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_AD_Sem_Kerberos>', 'Users_Without_Kerberos>'), '<Sessao ', '<Session ')
        WHERE 
            Id_Verificacao = 107
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Usuários SQL com permissão VIEW ANY DATABASE
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS 'Usuario/@name',
            A.principal_id AS 'Usuario/@principal_id',
            A.create_date AS 'Usuario/@create_date',
            A.modify_date AS 'Usuario/@modify_date',
            A.[type_desc] AS 'Usuario/@type_desc',
            B.state_desc AS 'Usuario/@state_desc'
        FROM
            sys.server_principals A
            JOIN sys.server_permissions B ON A.principal_id = B.grantee_principal_id
        WHERE
            B.[permission_name] = 'VIEW ANY DATABASE'
            AND B.[state] IN ('G', 'W')
            AND A.is_disabled = 0
            AND A.[type] NOT IN ('CERTIFICATE_MAPPED_LOGIN', 'WINDOWS_LOGIN', 'WINDOWS_GROUP')
            AND A.[name] = 'public'
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Permissao_View_Any_Database'), TYPE
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 108

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissao_View_Any_Database>', 'Users_View_Any_Database>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 108
        
    END

    ---------------------------------------------------------------------------------------------------------------
    -- BUILTIN SQL Permissions
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
       SELECT 
			pr.[name] AS 'Usuario/@name',
			pe.[permission_name] AS 'Usuario/@permission_name',
			pe.[state_desc] AS 'Usuario/@state_desc'
		FROM
			sys.server_principals pr JOIN sys.server_permissions pe
			ON pr.principal_id = pe.grantee_principal_id
		WHERE 
			pr.name like 'BUILTIN%'
        FOR XML PATH(''), ROOT('Permissao_BUILTIN'), TYPE
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 109

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissao_BUILTIN>', 'Users_BUILTIN>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 109
        
    END

    ---------------------------------------------------------------------------------------------------------------
    -- Local Windows Groups SQL Permissions
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
       SELECT
			pr.[name] AS 'Usuario/@LocalGroupName',
			pe.[permission_name] AS 'Usuario/@permission_name',
			pe.[state_desc] AS 'Usuario/@state_desc'
		FROM 
			sys.server_principals pr
				JOIN sys.server_permissions pe
					ON pr.[principal_id] = pe.[grantee_principal_id]
		WHERE 
			pr.[type_desc] = 'WINDOWS_GROUP'
			AND pr.[name] like CAST(SERVERPROPERTY('MachineName') AS nvarchar) + '%'
        FOR XML PATH(''), ROOT('Permissao_LOCAL'), TYPE
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 110

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissao_Local>', 'Users_Local_Group>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 110
        
    END        
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos xp_cmdshell estão permitidos na instância
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK)
        WHERE 
            [name] = 'xp_cmdshell'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 200

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 200
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos OLE Automation estão permitidos na instância
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'Ole Automation Procedures'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 201

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 201
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos SQLCLR estão permitidos na instância
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'clr enabled'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 202

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 202
        
    END

        
   
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos SQLCLR estão permitidos na instância
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @DadosSQLCLR TABLE ( [database_name] NVARCHAR(128), [assembly_name] nvarchar(128), [clr_name] nvarchar(256), [permission_set_desc] nvarchar(60), [create_date] datetime, [modify_date] datetime )

    INSERT INTO @DadosSQLCLR
    (
        [database_name],
        assembly_name,
        clr_name,
        permission_set_desc,
        create_date,
        modify_date
    )
    EXEC sys.sp_MSforeachdb
        @command1 = N'SELECT 
    ''?'',
    [name],
    clr_name,
    permission_set_desc,
    create_date,
    modify_date
FROM 
   [?].sys.assemblies WITH(NOLOCK)
WHERE 
    [permission_set] <> 1 
    AND is_user_defined = 1'
    
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database_name] AS 'Assembly/@database_name',
            assembly_name AS 'Assembly/@assembly_name',
            clr_name AS 'Assembly/@clr_name',
            permission_set_desc AS 'Assembly/@permission_set_desc',
            create_date AS 'Assembly/@create_date',
            modify_date AS 'Assembly/@modify_date'
        FROM 
            @DadosSQLCLR
        ORDER BY
            1, 2, 3
        FOR XML PATH(''), ROOT('Configuracao'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 203

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 203
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se comandos externos estão permitidos na instância
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            configuration_id,
            [name],
            [value],
            value_in_use,
            [description]
        FROM 
            sys.configurations WITH(NOLOCK) 
        WHERE 
            [name] = 'external scripts enabled'
            AND value_in_use = 1
        FOR XML PATH, ROOT('Configuracao')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 204

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Configuracao>', 'Configuration>')
        WHERE 
            Id_Verificacao = 204
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a base suporta TDE e se está ativado
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    IF (@Versao >= 2008)
    BEGIN

        SET @Resultado = (
            SELECT
                A.[name] AS 'Database/@name',
                A.[compatibility_level] AS 'Database/@compatibility_level'
            FROM
                sys.databases A WITH(NOLOCK)
                LEFT JOIN sys.dm_database_encryption_keys B WITH(NOLOCK) ON B.database_id = A.database_id
            WHERE
                B.database_id IS NULL
                AND A.[name] NOT IN ('master', 'model', 'msdb', 'tempdb', 'ReportServer', 'ReportServerTempDB')
                AND A.[state] = 0 -- ONLINE
            ORDER BY
                1
            FOR XML PATH(''), ROOT('Databases_Sem_TDE'), TYPE
        )

    END



    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Versao < 2008 THEN 'Não suportado' WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 300

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Versao < 2008 THEN 'Não suportado' WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Databases_Sem_TDE>', 'Databases_Without_TDE>')
        WHERE 
            Id_Verificacao = 300
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se os databases estão com backup atualizado
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[Name] AS 'Database/@Name',
            COALESCE(CONVERT(VARCHAR(12), MAX(B.backup_finish_date), 103) + ' ' + CONVERT(VARCHAR(12), MAX(B.backup_finish_date), 108) , '-') AS 'Database/@LastBackUpTime',
            DATEDIFF(DAY, ISNULL(MAX(B.backup_finish_date), MAX(A.create_date)), GETDATE()) AS 'Database/@Qt_Dias_Sem_Backup'
        FROM
            sys.databases A WITH(NOLOCK)
            LEFT JOIN msdb.dbo.backupset B WITH(NOLOCK) ON B.[database_name] = A.[name]
        WHERE
            A.[state] = 0 -- ONLINE
            AND A.[name] <> 'tempdb'
        GROUP BY
            A.[Name]
        HAVING
            DATEDIFF(DAY, ISNULL(MAX(B.backup_finish_date), MAX(A.create_date)), GETDATE()) > 7
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Databases_Sem_Backup'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 301

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Databases_Sem_Backup>', 'Databases_Without_Backup>')
        WHERE 
            Id_Verificacao = 301
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se foi realizado algum backup sem criptografia
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    IF (@Versao > 2012)
    BEGIN

        DECLARE @Backups_Sem_Criptografia TABLE ( 
            [database_name] NVARCHAR(128),
            key_algorithm NVARCHAR(32),
            encryptor_thumbprint VARBINARY(20),
            encryptor_type NVARCHAR(32),
            media_set_id INT,
            is_encrypted BIT,
            [type] CHAR(1),
            is_compressed BIT,
            physical_device_name NVARCHAR(260)
        )


        INSERT INTO @Backups_Sem_Criptografia
        EXEC('SELECT TOP(100)
            b.[database_name],
            b.key_algorithm,
            b.encryptor_thumbprint,
            b.encryptor_type,
            b.media_set_id,
            m.is_encrypted, 
            b.[type],
            m.is_compressed,
            bf.physical_device_name
        FROM
            msdb.dbo.backupset b WITH(NOLOCK)
            JOIN msdb.dbo.backupmediaset m WITH(NOLOCK) ON b.media_set_id = m.media_set_id
            JOIN msdb.dbo.backupmediafamily bf WITH(NOLOCK) on bf.media_set_id=b.media_set_id
        WHERE 
            m.is_encrypted = 0
        ORDER BY
            b.backup_start_date DESC')


        SET @Resultado = (
            SELECT 
                [database_name] AS 'Backup/@database_name',
                key_algorithm AS 'Backup/@key_algorithm',
                encryptor_thumbprint AS 'Backup/@encryptor_thumbprint',
                encryptor_type AS 'Backup/@encryptor_type',
                media_set_id AS 'Backup/@media_set_id',
                is_encrypted AS 'Backup/@is_encrypted',
                [type] AS 'Backup/@type',
                is_compressed AS 'Backup/@is_compressed',
                physical_device_name AS 'Backup/@physical_device_name'
            FROM 
                @Backups_Sem_Criptografia
            ORDER BY
                1
            FOR XML PATH(''), ROOT('Backups_Sem_Criptografia'), TYPE
        )

    END
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Versao <= 2008 THEN 'Não suportado' WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 302

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Versao <= 2008 THEN 'Not Supported' WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Backups_Sem_Criptografia>', 'Backups_Without_Encryption>')
        WHERE 
            Id_Verificacao = 302
        
    END

    
    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem databases com Recovery Model FULL e sem backup de LOG
    ---------------------------------------------------------------------------------------------------------------

    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.[name] AS 'Database/@name',
            MAX(B.backup_finish_date) AS 'Database/@backup_finish_date'
        FROM
            sys.databases A WITH(NOLOCK)
            LEFT JOIN msdb..backupset B WITH(NOLOCK) ON B.[database_name] = A.[name] AND B.[type] = 'L'
        WHERE
            A.recovery_model = 1 -- FULL
            AND A.[name] NOT IN ('master', 'msdb', 'tempdb', 'model')
            AND A.[state] = 0 -- ONLINE
        GROUP BY
            A.[name]
        HAVING
            DATEDIFF(DAY, ISNULL(MAX(B.backup_finish_date), '1900-01-01'), GETDATE()) > 1
        ORDER BY
            2 DESC
        FOR XML PATH(''), ROOT('Databases_Sem_Backup_de_LOG'), TYPE
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 303

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Databases_Sem_Backup_de_LOG>', 'Backups_Without_Log_Backup>')
        WHERE 
            Id_Verificacao = 303
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica a extensão dos arquivos do SQL Server
    ---------------------------------------------------------------------------------------------------------------
        
    SET @Resultado = (
        SELECT 
            [name] AS 'Database/@name',
            database_id AS 'Database/@database_id',
            [state_desc] AS 'Database/@state_desc',
            physical_name AS 'Database/@physical_name',
            size AS 'Database/@size',
            max_size AS 'Database/@max_size',
            growth AS 'Database/@growth',
            is_percent_growth AS 'Database/@is_percent_growth',
            is_read_only AS 'Database/@is_read_only',
            is_media_read_only AS 'Database/@is_media_read_only'                
        FROM
            sys.master_files
        WHERE
            RIGHT(physical_name, 3) IN ('ndf', 'ldf', 'mdf')
        FOR XML PATH(''), ROOT('Extensao_Padrao_Arquivos_SQL'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 304

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Extensao_Padrao_Arquivos_SQL>', 'SQL_Datafiles_Extension>')
        WHERE 
            Id_Verificacao = 304
        
    END

    
    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica a extensão dos arquivos de backup do SQL Server
    --------------------------------------------------------------------------------------------------------------- 

    IF (OBJECT_ID('tempdb..#Informacoes_Backups') IS NOT NULL) DROP TABLE #Informacoes_Backups
    SELECT 
        B.[database_name],
        A.logical_device_name,
        A.physical_device_name,
        B.[backup_start_date],
        B.[backup_finish_date],
        B.expiration_date,
        (CASE 
            WHEN @language = 'en' THEN
                (CASE B.[type] 
                    WHEN 'D' THEN 'Full'
                    WHEN 'I' THEN 'Differential'
                    WHEN 'L' THEN 'Log' 
                END)
            ELSE
                (CASE B.[type] 
                    WHEN 'D' THEN 'Full'
                    WHEN 'I' THEN 'Diferencial'
                    WHEN 'L' THEN 'Log' 
                END)
        END) AS backup_type,
        A.device_type,
        (CASE 
            WHEN @language = 'en' THEN
                (CASE A.device_type 
                    WHEN 2 THEN 'Disk' 
                    WHEN 5 THEN 'Tape' 
                    WHEN 7 THEN 'Virtual Device'
                    WHEN 9 THEN 'Azure Storage' 
                    WHEN 105 THEN 'Backup Unit' 
                END)
            ELSE
                (CASE A.device_type 
                    WHEN 2 THEN 'Disco' 
                    WHEN 5 THEN 'Fita' 
                    WHEN 7 THEN 'Dispositivo Virtual'
                    WHEN 9 THEN 'Azure Storage' 
                    WHEN 105 THEN 'Unidade de Backup' 
                END)
        END) AS device_type_desc,
        B.backup_size,
        B.[name] AS backupset_name,
        B.[description]
    INTO
        #Informacoes_Backups
    FROM
        msdb.dbo.backupmediafamily A WITH(NOLOCK)
        JOIN msdb.dbo.backupset B WITH(NOLOCK) ON A.media_set_id = B.media_set_id
        
       

    SET @Resultado = (
        SELECT TOP(50)
            A.[database_name] AS 'Database/@database_name',
            A.logical_device_name AS 'Database/@logical_device_name',
            A.physical_device_name AS 'Database/@physical_device_name',
            A.[backup_start_date] AS 'Database/@backup_start_date',
            A.[backup_finish_date] AS 'Database/@backup_finish_date',
            A.expiration_date AS 'Database/@expiration_date',
            A.backup_type AS 'Database/@backup_type',
            A.backup_size AS 'Database/@backup_size',
            A.backupset_name AS 'Database/@backupset_name',
            A.[description] AS 'Database/@description'
        FROM
            #Informacoes_Backups A
        WHERE
            device_type IN (2, 5) -- Disco e Fita
            AND A.backup_start_date >= DATEADD(DAY, -7, @Dt_Hoje )
            AND RIGHT(A.physical_device_name, 3) = 'bak'
        ORDER BY
            A.[database_name],
            A.backup_finish_date
        FOR XML PATH(''), ROOT('Extensao_Padrao_Backups_SQL'), TYPE
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 305

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Extensao_Padrao_Backups_SQL>', 'SQL_Backup_Extension>')
        WHERE 
            Id_Verificacao = 305
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a instância possui alguma solução de backup além de backup em disco
    ---------------------------------------------------------------------------------------------------------------
        
    SET @Resultado = (
        SELECT 
            A.[database_name] AS 'Database/@database_name',
            A.logical_device_name AS 'Database/@logical_device_name',
            COUNT(*) AS 'Database/@backup_count',
            MAX(A.[backup_start_date]) AS 'Database/@last_backup_start_date',
            MAX(A.[backup_finish_date]) AS 'Database/@last_backup_finish_date',
            MAX(A.expiration_date) AS 'Database/@last_expiration_date',
            A.device_type AS 'Database/@backup_type',
            A.device_type_desc AS 'Database/@backup_type_desc',
            A.[backupset_name] AS 'Database/@backupset_name',
            A.[description] AS 'Database/@description'
        FROM
            #Informacoes_Backups A
        WHERE
            A.backup_start_date >= DATEADD(DAY, -7, @Dt_Hoje )
            AND A.device_type = 2 -- Disco
            AND NOT EXISTS(SELECT NULL FROM #Informacoes_Backups WHERE [database_name] = A.[database_name] AND device_type <> 2 AND backup_start_date >= DATEADD(DAY, -7, @Dt_Hoje ) )
        GROUP BY
            A.[database_name],
            A.logical_device_name,
            A.device_type,
            A.device_type_desc,
            A.[backupset_name],
            A.[description]
        ORDER BY
            A.[database_name]
        FOR XML PATH(''), ROOT('Armazenamento_Backups_SQL'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 306

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Armazenamento_Backups_SQL>', 'Backup_Device>')
        WHERE 
            Id_Verificacao = 306
        
    END
    
   
   
    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com permissão CONTROL SERVER
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS 'Usuario/@login',
            A.principal_id AS 'Usuario/@principal_id',
            B.[permission_name] AS 'Usuario/@permission_name',
            A.[type_desc] AS 'Usuario/@type_desc',
            A.is_disabled AS 'Usuario/@is_disabled'
        FROM
            sys.server_principals A WITH(NOLOCK)
            JOIN (
                SELECT 
                    grantee_principal_id,
                    [permission_name] COLLATE SQL_Latin1_General_CP1_CI_AI AS [permission_name]
                FROM 
                    sys.server_permissions WITH(NOLOCK)
                WHERE 
                    class_desc = 'SERVER' 
                    AND [permission_name] IN (
                        'Administer bulk operations',
                        'Alter any availability group',
                        'Alter any connection',
                        'Alter any credential',
                        'Alter any database',
                        'Alter any endpoint',
                        'Alter any event notification',
                        'Alter any event session',
                        'Alter any linked server',
                        'Alter any login',
                        'Alter any server audit',
                        'Alter any server role',
                        'Alter resources',
                        'Alter server state',
                        'Alter Settings',
                        'Alter trace',
                        'Authenticate server',
                        'Control server',
                        'Create any database',
                        'Create availability group',
                        'Create DDL event notification',
                        'Create endpoint',
                        'Create server role',
                        'Create trace event notification',
                        'Shutdown'
                    ) 
                    AND [state] IN ('G', 'W')
                ) B ON A.principal_id = B.grantee_principal_id
            WHERE
                A.principal_id > 10
                AND A.[name] NOT IN ('##MS_PolicySigningCertificate##', '##MS_SQLReplicationSigningCertificate##', '##MS_SQLAuthenticatorCertificate##', 'NT AUTHORITY\SYSTEM', 'AUTORIDADE NT\SISTEMA')
                AND A.[name] NOT LIKE 'NT SERVICE\%'
                AND A.is_disabled = 0
            ORDER BY
                1
        FOR XML PATH(''), ROOT('Permissao_CONTROL_SERVER'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 400

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissao_CONTROL_SERVER>', 'CONTROL_SERVER_Permission>')
        WHERE 
            Id_Verificacao = 400
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Usuários nas roles sysadmin/securityadmin
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.[name] AS 'Login/@name',
            B.[permission_name] AS 'Login/@permission_name',
            A.[type_desc] AS 'Login/@type_desc',
            A.is_disabled AS 'Login/@is_disabled',
            A.principal_id AS 'Login/@principal_id',
            A.[sid] AS 'Login/@sid'
        FROM
            sys.server_principals A WITH(NOLOCK)
            JOIN (
                SELECT 
                    a1.member_principal_id AS grantee_principal_id,
                    a2.[name] COLLATE SQL_Latin1_General_CP1_CI_AI AS [permission_name]
                FROM 
                    sys.server_role_members AS a1 WITH(NOLOCK)
                    JOIN sys.server_principals AS a2 WITH(NOLOCK) ON a1.role_principal_id = a2.principal_id 
                WHERE 
                    a2.[name] IN ('sysadmin', 'securityadmin')
            ) B ON A.principal_id = B.grantee_principal_id
        WHERE
            A.principal_id > 10
            AND A.[name] <> '##MS_PolicySigningCertificate##'
            AND A.is_disabled = 0
            AND A.[name] NOT LIKE 'NT SERVICE\%'
            AND A.[name] NOT LIKE 'SERVIÇO NT\%'
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Sysadmin_SecurityAdmin'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 401

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Sysadmin_SecurityAdmin>', 'Sysadmin_SecurityAdmin_Users>')
        WHERE 
            Id_Verificacao = 401
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com IMPERSONATE ANY LOGIN
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.class AS 'Login/@class',
            A.class_desc AS 'Login/@class_desc',
            A.[type] AS 'Login/@type',
            A.[permission_name] AS 'Login/@permission_name',
            A.[state] AS 'Login/@state',
            A.state_desc AS 'Login/@state_desc',
            B.[name] AS 'Login/@grantee', -- quem recebeu a permissão
            C.[name] AS 'Login/@grantor' -- quem concedeu a permissão
        FROM 
            sys.server_permissions A WITH(NOLOCK)
            JOIN sys.server_principals B WITH(NOLOCK) ON A.grantee_principal_id = B.principal_id
            LEFT JOIN sys.server_principals C WITH(NOLOCK) ON A.grantor_principal_id = C.principal_id
        WHERE
            A.[type] = 'IAL'
            AND A.[state] = 'G'
        ORDER BY
            7
        FOR XML PATH(''), ROOT('Usuarios_Impersonate_Any_Login'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 402

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Impersonate_Any_Login>', 'Users_Impersonate_Any_Login>')
        WHERE 
            Id_Verificacao = 402
        
    END
        


    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com IMPERSONATE LOGIN
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.class AS 'Login/@class',
            A.class_desc AS 'Login/@class_desc',
            A.[type] AS 'Login/@type',
            A.[permission_name] AS 'Login/@permission_name',
            A.[state] AS 'Login/@state',
            A.state_desc AS 'Login/@state_desc',
            B.[name] AS 'Login/@grantee', -- quem recebeu a permissão
            C.[name] AS 'Login/@grantor' -- quem concedeu a permissão
        FROM 
            sys.server_permissions A WITH(NOLOCK)
            JOIN sys.server_principals B WITH(NOLOCK) ON A.grantee_principal_id = B.principal_id
            LEFT JOIN sys.server_principals C WITH(NOLOCK) ON A.grantor_principal_id = C.principal_id
        WHERE
            A.[type] = 'IM'
            AND A.[state] = 'G'
        ORDER BY
            7
        FOR XML PATH(''), ROOT('Usuarios_Impersonate_Login'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 403

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Impersonate_Login>', 'Users_Impersonate_Login>')
        WHERE 
            Id_Verificacao = 403
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com sysadmin/securityadmin que podem ser personificados
    ---------------------------------------------------------------------------------------------------------------

    -- DECLARE @Resultado XML
    SET @Resultado = NULL

    ;WITH cte
    AS (
   
        SELECT
            grantee_principal_id
        FROM
            sys.server_permissions WITH(NOLOCK)
        WHERE
            [permission_name] = 'IMPERSONATE'
            AND class_desc = 'SERVER_PRINCIPAL'
            AND major_id IN (

                SELECT 
                    grantee_principal_id
                FROM 
                    sys.server_permissions WITH(NOLOCK)
                WHERE 
                    class_desc = 'SERVER' 
                    AND [permission_name] IN (
                        'Administer bulk operations',
                        'Alter any availability group',
                        'Alter any connection',
                        'Alter any credential',
                        'Alter any database',
                        'Alter any endpoint',
                        'Alter any event notification',
                        'Alter any event session',
                        'Alter any linked server',
                        'Alter any login',
                        'Alter any server audit',
                        'Alter any server role',
                        'Alter resources',
                        'Alter server state',
                        'Alter Settings',
                        'Alter trace',
                        'Authenticate server',
                        'Control server',
                        'Create any database',
                        'Create availability group',
                        'Create DDL event notification',
                        'Create endpoint',
                        'Create server role',
                        'Create trace event notification',
                        'Shutdown',
                        'IMPERSONATE ANY LOGIN'
                    )
                    AND [state] IN ('G', 'W')

                UNION

                SELECT 
                    a1.member_principal_id
                FROM 
                    sys.server_role_members AS a1 WITH(NOLOCK)
                    JOIN sys.server_principals AS a2 WITH(NOLOCK) ON a1.role_principal_id = a2.principal_id 
                WHERE 
                    a2.[name] IN ('sysadmin', 'securityadmin')
            )

        UNION ALL

        SELECT
            p.grantee_principal_id
        FROM
            cte
            JOIN sys.server_permissions AS p WITH(NOLOCK) ON p.[permission_name] = 'IMPERSONATE' AND p.class_desc = 'SERVER_PRINCIPAL' AND p.major_id = cte.grantee_principal_id 
    )
    SELECT @Resultado = (
        SELECT
            A.[name] AS [login]
        FROM
            master.sys.server_principals AS A WITH(NOLOCK)
        WHERE
            A.principal_id IN
            (
                SELECT
                    grantee_principal_id
                FROM
                    cte
            )
        ORDER BY
            1
        FOR XML PATH, ROOT('Usuarios_Impersonate_Login_Sysadmin')
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 404

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Impersonate_Login_Sysadmin>', 'Users_Impersonate_Login_Sysadmin>')
        WHERE 
            Id_Verificacao = 404
        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Usuários nas database roles db_owner/db_securityadmin
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Usuarios_DB_Owners TABLE ( [database_name] VARCHAR(256), [user] VARCHAR(256), [database_role] VARCHAR(256) )
    
    INSERT INTO @Usuarios_DB_Owners
    EXEC master.dbo.sp_MSforeachdb '
    SELECT 
        ''?'' AS [database],
        B.[name] AS [user],
        C.[name] AS [database_role]
    FROM
        [?].sys.database_role_members A WITH(NOLOCK)
        JOIN [?].sys.database_principals B WITH(NOLOCK) ON A.member_principal_id = B.principal_id
        JOIN [?].sys.database_principals C WITH(NOLOCK) ON A.role_principal_id = C.principal_id
    WHERE
        C.[name] IN (''db_owner'', ''db_securityadmin'')
        AND B.[name] <> ''dbo''
        AND B.[name] <> ''RSExecRole'''



    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database_name] AS 'Usuario/@database_name',
            [user] AS 'Usuario/@user',
            database_role AS 'Usuario/@database_role'
        FROM
            @Usuarios_DB_Owners
        ORDER BY
            1, 2, 3
        FOR XML PATH(''), ROOT('Usuarios_DB_Owners'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 405

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_DB_Owners>', 'Users_DB_Owner>'), '<Usuario ', '<User '), 'usuario=', 'user=')
        WHERE 
            Id_Verificacao = 405
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com privilégios de IMPERSONATE USER no database
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Impersonate_User TABLE ( [database] nvarchar(128), [class_desc] nvarchar(60), [permission_name] nvarchar(128), [state_desc] nvarchar(60), [grantee] nvarchar(128), [impersonated_user] nvarchar(128) )

    INSERT INTO @Impersonate_User
    EXEC sys.sp_MSforeachdb '
    SELECT
        ''?'' as [database],
        A.class_desc,
        A.state_desc,
        A.[permission_name],
        B.[name] AS grantee,
        C.[name] AS impersonated_user
    FROM
        [?].sys.database_permissions A WITH(NOLOCK)
        JOIN [?].sys.database_principals B WITH(NOLOCK) ON A.grantee_principal_id = B.principal_id
        LEFT JOIN [?].sys.database_principals C WITH(NOLOCK) ON A.grantor_principal_id = C.principal_id
    WHERE
        A.[type] = ''IM''
        AND A.[state] IN (''G'', ''W'')
        AND C.[name] <> ''MS_DataCollectorInternalUser'''


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            [database] AS 'Usuario/@database',
            class_desc AS 'Usuario/@class_desc',
            [permission_name] AS 'Usuario/@permission_name',
            state_desc AS 'Usuario/@state_desc',
            grantee AS 'Usuario/@grantee',
            impersonated_user AS 'Usuario/@impersonated_user'
        FROM
            @Impersonate_User
        ORDER BY
            6, 1
        FOR XML PATH(''), ROOT('Usuarios_Impersonate_User'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 406

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Impersonate_User>', 'Users_Impersonate>')
        WHERE 
            Id_Verificacao = 406
        
    END


        
    ---------------------------------------------------------------------------------------------------------------
    -- Permissões da role PUBLIC
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Permissoes_Public TABLE ( [database] nvarchar(128), [class_desc] nvarchar(60), [state_desc] nvarchar(60), [permission_name] nvarchar(128), [object_name] nvarchar(128), is_ms_shipped bit  )

        INSERT INTO @Permissoes_Public
        EXEC sys.sp_MSforeachdb '
        SELECT
            ''?'' as [database],
            A.class_desc,
            A.state_desc,
            A.[permission_name],
            B.[name],
            B.is_ms_shipped
        FROM 
            [?].sys.database_permissions A WITH(NOLOCK)
            LEFT JOIN [?].sys.all_objects B WITH(NOLOCK) ON A.major_id = B.[object_id]
        WHERE 
            A.grantee_principal_id = 0
            AND A.state IN (''G'', ''W'')
            AND (A.major_id = 0 OR B.[object_id] IS NOT NULL)
            AND ''?'' <> ''tempdb'''

    
        SET @Resultado = NULL

        IF (EXISTS(SELECT NULL FROM @Permissoes_Public))
        BEGIN

            SET @Resultado = (
                SELECT NULL,
                (
                    SELECT TOP(50)
                        [database] AS 'Objetos_Sistema/@database',
                        class_desc AS 'Objetos_Sistema/@class_desc',
                        state_desc AS 'Objetos_Sistema/@state_desc',
                        [permission_name] AS 'Objetos_Sistema/@permission_name',
                        [object_name] AS 'Objetos_Sistema/@object_name'
                    FROM
                        @Permissoes_Public
                    WHERE
                        is_ms_shipped = 1
                        OR (
                            [database] = 'msdb'
                            AND [object_name] LIKE 'sp_DTA_%'
                        )
                        OR ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                    ORDER BY
                        1, 5
                    FOR
                        XML PATH(''), ROOT('Sistema'), TYPE
                ),
                (
                    SELECT TOP(50)
                        [database] AS 'Objetos_Usuario/@database',
                        class_desc AS 'Objetos_Usuario/@class_desc',
                        state_desc AS 'Objetos_Usuario/@state_desc',
                        [permission_name] AS 'Objetos_Usuario/@permission_name',
                        [object_name] AS 'Objetos_Usuario/@object_name'
                    FROM
                        @Permissoes_Public
                    WHERE
                        is_ms_shipped = 0
                        AND NOT (
                            [database] = 'msdb'
                            AND [object_name] LIKE 'sp_DTA_%'
                        )
                        AND NOT ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                    ORDER BY
                        1, 5
                    FOR
                        XML PATH(''), ROOT('Usuario'), TYPE
                )
                FOR XML PATH(''), ROOT('Permissoes_Public')
            )

        END



        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 407

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissoes_Public>', 'Public_Permissions>'), '<Objetos_Sistema', '<System_Objects'), '<Objetos_Usuario', 'User_Objects')
            WHERE 
                Id_Verificacao = 407
        
        END


    END

        
    ---------------------------------------------------------------------------------------------------------------
    -- Permissões do usuário GUEST
    ---------------------------------------------------------------------------------------------------------------

    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Permissoes_Guest TABLE ( [database] nvarchar(128), [class_desc] nvarchar(60), [state_desc] nvarchar(60), [permission_name] nvarchar(128), [object_name] nvarchar(128), is_ms_shipped bit )

        INSERT INTO @Permissoes_Guest
        EXEC sys.sp_MSforeachdb '
        SELECT
            ''?'' as [database],
            A.class_desc,
            A.state_desc,
            A.[permission_name],
            B.[name],
            ISNULL(B.is_ms_shipped, 0) AS is_ms_shipped
        FROM 
            [?].sys.database_permissions A WITH(NOLOCK)
            LEFT JOIN [?].sys.all_objects B WITH(NOLOCK) ON A.major_id = B.[object_id]
        WHERE 
            A.grantee_principal_id = 2
            AND A.state IN (''G'', ''W'')
            AND (A.major_id = 0 OR B.[object_id] IS NOT NULL)
            AND NOT(''?'' IN (''master'', ''tempdb'', ''model'', ''msdb'') AND A.[permission_name] = ''CONNECT'')'

    
    
        SET @Resultado = NULL

        IF (EXISTS(SELECT NULL FROM @Permissoes_Guest))
        BEGIN

            SET @Resultado = (
                SELECT NULL,
                (
                    SELECT 
                        [database] AS 'Objetos_Sistema/@database',
                        class_desc AS 'Objetos_Sistema/@class_desc',
                        state_desc AS 'Objetos_Sistema/@state_desc',
                        [permission_name] AS 'Objetos_Sistema/@permission_name',
                        [object_name] AS 'Objetos_Sistema/@object_name'
                    FROM
                        @Permissoes_Guest
                    WHERE
                        is_ms_shipped = 1
                        OR (
                            [database] = 'msdb'
                            AND [object_name] LIKE 'sp_DTA_%'
                        )
                        OR ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                    ORDER BY
                        1, 5
                    FOR
                        XML PATH(''), ROOT('Sistema'), TYPE
                ),
                (
                    SELECT 
                        [database] AS 'Objetos_Usuario/@database',
                        class_desc AS 'Objetos_Usuario/@class_desc',
                        state_desc AS 'Objetos_Usuario/@state_desc',
                        [permission_name] AS 'Objetos_Usuario/@permission_name',
                        [object_name] AS 'Objetos_Usuario/@object_name'
                    FROM
                        @Permissoes_Guest
                    WHERE
                        is_ms_shipped = 0
                        AND NOT (
                            [database] = 'msdb'
                            AND [object_name] LIKE 'sp_DTA_%'
                        )
                        AND NOT ([object_name] IN ('fn_diagramobjects', 'sp_alterdiagram', 'sp_creatediagram', 'sp_dropdiagram', 'sp_helpdiagramdefinition', 'sp_helpdiagrams', 'sp_renamediagram', 'dt_whocheckedout_u'))
                    ORDER BY
                        1, 5
                    FOR
                        XML PATH(''), ROOT('Usuario'), TYPE
                )
                FOR XML PATH, ROOT('Permissoes_Guest')
            )

        END


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 408

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissoes_Guest>', 'Guest_Permissions>'), '<Objetos_Sistema ', '<System_Objects '), '<Objetos_Usuario ', 'User_Objects ')
            WHERE 
                Id_Verificacao = 408
        
        END


    END



    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com permissões UNSAFE/EXTERNAL ASSEMBLY
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            A.[name] AS 'Usuario/@login',
            B.class_desc AS 'Usuario/@class_desc',
            B.state_desc AS 'Usuario/@state_desc',
            B.[permission_name] AS 'Usuario/@permission_name'
        FROM
            sys.server_principals A WITH(NOLOCK)
            JOIN sys.server_permissions B WITH(NOLOCK) ON A.principal_id = B.grantee_principal_id
        WHERE
            B.[type] IN ('XU', 'XA')
            AND B.[state] IN ('G', 'W')
        ORDER BY
            1
        FOR XML PATH(''), ROOT('Usuarios_Unsafe_External_Assembly'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 409

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Usuarios_Unsafe_External_Assembly>', 'Users_Unsafe_External_Assembly>'), '<Usuario ', '<User ')
        WHERE 
            Id_Verificacao = 409
        
    END

    
    ---------------------------------------------------------------------------------------------------------------
    -- Usuários com permissões em extended procedures (xp_%)
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    SET @Resultado = (
        SELECT
            u.[name] AS 'Permissao/@user',
            o.[name] AS 'Permissao/@stored_procedure',
            u.[type_desc] AS 'Permissao/@type',
            p.class_desc AS 'Permissao/@class_desc',
            p.[permission_name] AS 'Permissao/@permission_name',
            p.state_desc AS 'Permissao/@state_desc',
            'REVOKE ' + p.[permission_name] + ' ON sys.[' + o.[name] COLLATE DATABASE_DEFAULT + '] FROM [' + u.[name] + '];' AS 'Permissao/@RevokeCommand',
            'GRANT ' + p.[permission_name] + ' ON sys.[' + o.[name] COLLATE DATABASE_DEFAULT + '] TO [' + u.[name] + '];' AS 'Permissao/@GrantCommand'
        FROM
            [master].sys.system_objects o
            JOIN [master].sys.database_permissions p ON o.[object_id] = p.major_id
            JOIN [master].sys.database_principals u ON p.grantee_principal_id = u.principal_id
        WHERE
            (o.[name] LIKE 'xp_%')
            AND o.[name] NOT IN ('xp_msver', 'xp_qv') /*'xp_instance_regread'*/ -- SP's necessárias pelo Object Explorer do SSMS
            --AND p.[type] = 'EX'
            AND p.[state] IN ('G', 'W') 
        ORDER BY
            o.[name],
            u.[name]
        FOR XML PATH(''), ROOT('Permissoes_Extended_Procedures'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 410

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Permissoes_Extended_Procedures>', 'Permissions_Extended_Procedures>'), '<Permissao ', '<Permission ')
        WHERE 
            Id_Verificacao = 410
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Objetos com IMPERSONATE
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Objetos_Com_Impersonate TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128), [Ds_Usuario] nvarchar(256) )

        INSERT INTO @Objetos_Com_Impersonate
        EXEC sys.sp_MSforeachdb '
        IF (''?'' <> ''tempdb'')
        BEGIN

            SELECT 
                ''?'' AS Ds_Database,
                B.[name],
                B.[type_desc],
                (CASE WHEN A.execute_as_principal_id = -2 THEN ''OWNER'' ELSE C.[name] END) AS Ds_Execute_As
            FROM
                [?].sys.sql_modules A WITH(NOLOCK)
                JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
                LEFT JOIN [?].sys.database_principals C WITH(NOLOCK) ON A.execute_as_principal_id = C.principal_id
            WHERE
                A.execute_as_principal_id IS NOT NULL
                AND C.[name] <> ''dbo''
                AND B.is_ms_shipped = 0
            
        END'


        SET @Resultado = NULL

        SET @Resultado = (
            SELECT 
                Ds_Database AS 'Objeto/@database',
                Ds_Objeto AS 'Objeto/@object',
                Ds_Tipo AS 'Objeto/@type',
                Ds_Usuario AS 'Objeto/@user'
            FROM
                @Objetos_Com_Impersonate
            ORDER BY
                1, 2, 4
            FOR XML PATH(''), ROOT('Objetos_Com_IMPERSONATE'), TYPE
        )


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 500

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Objetos_Com_IMPERSONATE>', 'Objects_With_Impersonate>'), '<Objeto ', '<Object ')
            WHERE 
                Id_Verificacao = 500
        
        END


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Objetos com query dinâmica
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Objetos_Query_Dinamica TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )


        IF (OBJECT_ID('tempdb.dbo.#Palavras_Exec') IS NOT NULL) DROP TABLE #Palavras_Exec
        CREATE TABLE #Palavras_Exec (
            Palavra VARCHAR(100) COLLATE SQL_Latin1_General_CP1_CI_AI
        )

        INSERT INTO #Palavras_Exec
        VALUES('%EXEC (%'), ('%EXEC(%'), ('%EXECUTE (%'), ('%EXECUTE(%'), ('%sp_executesql%')


        INSERT INTO @Objetos_Query_Dinamica
        EXEC sys.sp_MSforeachdb '
        IF (''?'' <> ''tempdb'')
        BEGIN

            SELECT DISTINCT TOP(100)
                ''?'' AS Ds_Database,
                B.[name],
                B.[type_desc]
            FROM
                [?].sys.sql_modules A WITH(NOLOCK)
                JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
                JOIN #Palavras_Exec C WITH(NOLOCK) ON A.[definition] COLLATE SQL_Latin1_General_CP1_CI_AI LIKE C.Palavra
            WHERE
                B.is_ms_shipped = 0
                AND ''?'' <> ''ReportServer''
                AND B.[name] NOT IN (''stpChecklist_Seguranca'', ''sp_WhoIsActive'', ''sp_showindex'', ''sp_AllNightLog'', ''sp_AllNightLog_Setup'', ''sp_Blitz'', ''sp_BlitzBackups'', ''sp_BlitzCache'', ''sp_BlitzFirst'', ''sp_BlitzIndex'', ''sp_BlitzLock'', ''sp_BlitzQueryStore'', ''sp_BlitzWho'', ''sp_DatabaseRestore'')
                AND NOT (B.[name] LIKE ''stp_DTA_%'' AND ''?'' = ''msdb'')
                AND NOT (B.[name] = ''sp_readrequest'' AND ''?'' = ''master'')
                AND EXISTS (
                    SELECT NULL
                    FROM [?].sys.parameters X1 WITH(NOLOCK)
                    JOIN [?].sys.types X2 WITH(NOLOCK) ON X1.system_type_id = X2.user_type_id
                    WHERE A.[object_id] = X1.[object_id]
                    AND X2.[name] IN (''text'', ''ntext'', ''varchar'', ''nvarchar'')
                    AND (X1.max_length > 10 OR X1.max_length < 0)
                )
            
        END'

    
        
        SET @Resultado = NULL

        SET @Resultado = (
            SELECT 
                Ds_Database AS 'Objeto/@database',
                Ds_Objeto AS 'Objeto/@object',
                Ds_Tipo AS 'Objeto/@type'
            FROM
                @Objetos_Query_Dinamica
            ORDER BY
                1, 2
            FOR XML PATH(''), ROOT('Objetos_Query_Dinamica'), TYPE
        )


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 501

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Objetos_Query_Dinamica>', 'Objects_With_Dynamic_Query>'), '<Objeto ', '<Object ')
            WHERE 
                Id_Verificacao = 501
        
        END

        
    END



    ---------------------------------------------------------------------------------------------------------------
    -- Objetos utilizando xp_cmdshell
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Objetos_xp_cmdshell TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )

        INSERT INTO @Objetos_xp_cmdshell
        EXEC sys.sp_MSforeachdb '
        IF (''?'' <> ''tempdb'')
        BEGIN

            SELECT TOP 100
                ''?'' AS Ds_Database,
                B.[name],
                B.[type_desc]
            FROM
                [?].sys.sql_modules A WITH(NOLOCK)
                JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
            WHERE
                B.is_ms_shipped = 0
                AND ''?'' <> ''ReportServer''
                AND B.[name] NOT IN (''stpChecklist_Seguranca'', ''sp_WhoIsActive'', ''sp_showindex'', ''sp_AllNightLog'', ''sp_AllNightLog_Setup'', ''sp_Blitz'', ''sp_BlitzBackups'', ''sp_BlitzCache'', ''sp_BlitzFirst'', ''sp_BlitzIndex'', ''sp_BlitzLock'', ''sp_BlitzQueryStore'', ''sp_BlitzWho'', ''sp_DatabaseRestore'')
                AND A.definition LIKE ''%xp_cmdshell%''
    
        END'

        
        SET @Resultado = NULL

        SET @Resultado = (
            SELECT 
                Ds_Database AS 'Objeto/@database',
                Ds_Objeto AS 'Objeto/@object',
                Ds_Tipo AS 'Objeto/@type'
            FROM
                @Objetos_xp_cmdshell
            ORDER BY
                1, 2
            FOR XML PATH(''), ROOT('Objetos_Utilizando_xp_cmdshell'), TYPE
        )


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 502

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Objetos_Utilizando_xp_cmdshell>', 'Objects_With_xp_cmdshell>'), '<Objeto ', '<Object ')
            WHERE 
                Id_Verificacao = 502
        
        END


    END

        

    ---------------------------------------------------------------------------------------------------------------
    -- Objetos utilizando OLE Automation Procedures
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Objetos_OLE_Automation TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )

        INSERT INTO @Objetos_OLE_Automation
        EXEC sys.sp_MSforeachdb '
        IF (''?'' <> ''tempdb'')
        BEGIN

            SELECT TOP(100)
                ''?'' AS Ds_Database,
                B.[name],
                B.[type_desc]
            FROM
                [?].sys.sql_modules A WITH(NOLOCK)
                JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
            WHERE
                B.is_ms_shipped = 0
                AND ''?'' <> ''ReportServer''
                AND B.[name] NOT IN (''stpChecklist_Seguranca'', ''sp_WhoIsActive'', ''sp_showindex'', ''sp_AllNightLog'', ''sp_AllNightLog_Setup'', ''sp_Blitz'', ''sp_BlitzBackups'', ''sp_BlitzCache'', ''sp_BlitzFirst'', ''sp_BlitzIndex'', ''sp_BlitzLock'', ''sp_BlitzQueryStore'', ''sp_BlitzWho'', ''sp_DatabaseRestore'')
                AND B.[name] NOT IN (''dt_addtosourcecontrol'', ''dt_addtosourcecontrol_u'', ''dt_adduserobject'', ''dt_adduserobject_vcs'', ''dt_checkinobject'', ''dt_checkinobject_u'', ''dt_checkoutobject'', ''dt_checkoutobject_u'', ''dt_displayoaerror'', ''dt_displayoaerror_u'', ''dt_droppropertiesbyid'', ''dt_dropuserobjectbyid'', ''dt_generateansiname'', ''dt_getobjwithprop'', ''dt_getobjwithprop_u'', ''dt_getpropertiesbyid'', ''dt_getpropertiesbyid_u'', ''dt_getpropertiesbyid_vcs'', ''dt_getpropertiesbyid_vcs_u'', ''dt_isundersourcecontrol'', ''dt_isundersourcecontrol_u'', ''dt_removefromsourcecontrol'', ''dt_setpropertybyid'', ''dt_setpropertybyid_u'', ''dt_validateloginparams'', ''dt_validateloginparams_u'', ''dt_vcsenabled'', ''dt_verstamp006'', ''dt_verstamp007'', ''dt_whocheckedout'', ''dt_whocheckedout_u'')
                AND A.definition LIKE ''%sp_OACreate%''
            
        END'

        
        SET @Resultado = NULL

        SET @Resultado = (
            SELECT
                Ds_Database AS 'Objeto/@database',
                Ds_Objeto AS 'Objeto/@object',
                Ds_Tipo AS 'Objeto/@type'
            FROM
                @Objetos_OLE_Automation
            ORDER BY
                1, 2
            FOR XML PATH(''), ROOT('Objetos_Utilizando_OLE_Automation'), TYPE
        )

        
        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 503

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Objetos_Utilizando_OLE_Automation>', 'Objects_With_OLE_Automation>'), '<Objeto ', '<Object ')
            WHERE 
                Id_Verificacao = 503
        
        END


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Procedures executadas automaticamente na inicialização do SQL Server
    ---------------------------------------------------------------------------------------------------------------
    
    DECLARE @Procedures_Executadas_Automaticamente TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128), [Dt_Criacao] datetime, [Dt_Modificacao] datetime, [SP_Microsoft] bit )

    INSERT INTO @Procedures_Executadas_Automaticamente
    EXEC sys.sp_MSforeachdb '
    SELECT TOP 100
        ''?'' AS Ds_Database,
        [name],
        [type_desc],
        [create_date],
        [modify_date],
        is_ms_shipped
    FROM 
        sys.procedures WITH(NOLOCK)
    WHERE 
        is_auto_executed = 1'

        
    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            Ds_Database AS 'Procedure/@database',
            Ds_Objeto AS 'Procedure/@name',
            Ds_Tipo AS 'Procedure/@type_desc',
            Dt_Criacao AS 'Procedure/@create_date',
            Dt_Modificacao AS 'Procedure/@modify_date',
            SP_Microsoft AS 'Procedure/@is_ms_shipped'
        FROM
            @Procedures_Executadas_Automaticamente
        ORDER BY
            1, 2
        FOR XML PATH(''), ROOT('Procedures_Executadas_Automaticamente'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 504

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Procedures_Executadas_Automaticamente>', 'Startup_Procedures>'), '<Objeto ', '<Object ')
        WHERE 
            Id_Verificacao = 504
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Objetos com comandos de GRANT
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@heavy_operations = 1)
    BEGIN

        DECLARE @Objetos_Com_Grant TABLE ( [Ds_Database] nvarchar(256), [Ds_Objeto] nvarchar(256), [Ds_Tipo] nvarchar(128) )

        INSERT INTO @Objetos_Com_Grant
        EXEC sys.sp_MSforeachdb '
        IF (''?'' <> ''tempdb'')
        BEGIN

            SELECT TOP(100)
                ''?'' AS Ds_Database,
                B.[name],
                B.[type_desc]
            FROM
                [?].sys.sql_modules A WITH(NOLOCK)
                JOIN [?].sys.objects B WITH(NOLOCK) ON B.[object_id] = A.[object_id]
            WHERE
                B.is_ms_shipped = 0
                AND A.definition LIKE ''%GRANT %''
                AND ''?'' NOT IN (''master'', ''ReportServer'')
                AND B.[name] NOT IN (''dt_addtosourcecontrol'', ''dt_addtosourcecontrol_u'', ''dt_adduserobject'', ''dt_adduserobject_vcs'', ''dt_checkinobject'', ''dt_checkinobject_u'', ''dt_checkoutobject'', ''dt_checkoutobject_u'', ''dt_displayoaerror'', ''dt_displayoaerror_u'', ''dt_droppropertiesbyid'', ''dt_dropuserobjectbyid'', ''dt_generateansiname'', ''dt_getobjwithprop'', ''dt_getobjwithprop_u'', ''dt_getpropertiesbyid'', ''dt_getpropertiesbyid_u'', ''dt_getpropertiesbyid_vcs'', ''dt_getpropertiesbyid_vcs_u'', ''dt_isundersourcecontrol'', ''dt_isundersourcecontrol_u'', ''dt_removefromsourcecontrol'', ''dt_setpropertybyid'', ''dt_setpropertybyid_u'', ''dt_validateloginparams'', ''dt_validateloginparams_u'', ''dt_vcsenabled'', ''dt_verstamp006'', ''dt_verstamp007'', ''dt_whocheckedout'', ''dt_whocheckedout_u'', ''stpChecklist_Seguranca'')
            
        END'

        
        SET @Resultado = NULL

        SET @Resultado = (
            SELECT 
                Ds_Database AS 'Objeto/@database',
                Ds_Objeto AS 'Objeto/@object',
                Ds_Tipo AS 'Objeto/@type'
            FROM
                @Objetos_Com_Grant
            ORDER BY
                1, 2
            FOR XML PATH(''), ROOT('Objetos_Utilizando_Grant'), TYPE
        )


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 505

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Objetos_Utilizando_Grant>', 'Objects_With_Grants>'), '<Objeto ', '<Object ')
            WHERE 
                Id_Verificacao = 505
        
        END

    
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Linked Servers que utilizam usuário fixo
    ---------------------------------------------------------------------------------------------------------------


    SET @Resultado = NULL

    SET @Resultado = (
        SELECT 
            A.server_id AS 'LinkedServer/@server_id',
            A.[name] AS 'LinkedServer/@name',
            B.remote_name AS 'LinkedServer/@remote_name',
            A.product AS 'LinkedServer/@product',
            A.[provider] AS 'LinkedServer/@provider',
            A.[data_source] AS 'LinkedServer/@data_source',
            A.[catalog] AS 'LinkedServer/@catalog'
        FROM 
            sys.servers A WITH(NOLOCK)
            JOIN sys.linked_logins B WITH(NOLOCK) ON B.server_id = A.server_id
        WHERE
            A.is_linked = 1
            AND B.uses_self_credential = 0
        ORDER BY
            2, 3
        FOR XML PATH(''), ROOT('LinkedServer_Usuario_Fixo'), TYPE
    )

    
    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 506

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'LinkedServer_Usuario_Fixo>', 'LinkedServer_Fixed_User>')
        WHERE 
            Id_Verificacao = 506
        
    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o SQL Server está sendo executado na porta padrão 1433
    ---------------------------------------------------------------------------------------------------------------
    
    SET @Resultado = NULL

    IF (@PortaUtilizada = 1433)
    BEGIN

        SET @Resultado = (
            SELECT @PortaUtilizada AS Porta_Utilizada
            FOR XML PATH, ROOT('Porta_Utilizada')
        )

    END
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 600

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Porta_Utilizada>', 'Used_Port>')
        WHERE 
            Id_Verificacao = 600
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o SQL Browser está sendo executado sem necessidade (apenas 1 instância)
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN


        SET @Resultado = NULL

        IF ((SELECT COUNT(*) FROM @GetInstances) <= 1)
        BEGIN

            DECLARE @SQL_Browser_Instalado TABLE ( Valor INT )

            INSERT INTO @SQL_Browser_Instalado (Valor)
            EXEC master.sys.xp_regread 'HKEY_LOCAL_MACHINE', 'System\CurrentControlSet\Services\SQLBrowser'

            IF ((SELECT TOP(1) Valor FROM @SQL_Browser_Instalado) = 1)
            BEGIN
    
                DECLARE @SQL_Browser_Ativo TABLE ( Resultado VARCHAR(100) )

                INSERT INTO @SQL_Browser_Ativo ( Resultado )
                EXEC master.dbo.xp_servicecontrol N'QUERYSTATE',N'sqlbrowser'

                IF ((SELECT TOP(1) Resultado FROM @SQL_Browser_Ativo) LIKE '%Running%')
                BEGIN
        
                    SET @Resultado = (
                        SELECT *
                        FROM @GetInstances
                        FOR XML PATH, ROOT('SQL_Browser_Rodando_Apenas_1_Instancia')
                    )

                END

            END

        END



        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 601

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'SQL_Browser_Rodando_Apenas_1_Instancia>', 'SQL_Browser_1_Instance>')
            WHERE 
                Id_Verificacao = 601
        
        END


    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a configuração "Hide Instance" está ativada
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

    
        DECLARE @HideInstance INT 

        EXEC master..xp_instance_regread 
              @rootkey = N'HKEY_LOCAL_MACHINE', 
              @key = N'SOFTWARE\Microsoft\Microsoft SQL Server\MSSQLServer\SuperSocketNetLib', 
              @value_name = N'HideInstance',
              @value = @HideInstance OUTPUT

    
        SET @Resultado = NULL

        IF (@HideInstance = 0)
        BEGIN

            SET @Resultado = (
                SELECT @HideInstance AS [HideInstance]
                FOR XML PATH, ROOT('Instalacao_HideInstance')
            )

        END


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 602

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_HideInstance>', 'Installation_HideInstance>')
            WHERE 
                Id_Verificacao = 602
        
        END


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica as contas que o SQL Server está utilizando para iniciar os serviços
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE 
            @DBEngineLogin VARCHAR(100),
            @AgentLogin VARCHAR(100)

        EXECUTE master.dbo.xp_instance_regread
            @rootkey = N'HKEY_LOCAL_MACHINE',
            @key = N'SYSTEM\CurrentControlSet\Services\MSSQLServer',
            @value_name = N'ObjectName',
            @value = @DBEngineLogin OUTPUT

        EXECUTE master.dbo.xp_instance_regread
            @rootkey = N'HKEY_LOCAL_MACHINE',
            @key = N'SYSTEM\CurrentControlSet\Services\SQLServerAgent',
            @value_name = N'ObjectName',
            @value = @AgentLogin OUTPUT


        SET @Resultado = NULL

        IF (@DBEngineLogin LIKE 'NT SERVICE\%' OR @AgentLogin LIKE 'NT SERVICE\%' OR @DBEngineLogin = 'LocalSystem' OR @AgentLogin = 'LocalSystem' OR @DBEngineLogin LIKE 'NT AUTHORITY\%' OR @AgentLogin LIKE 'NT AUTHORITY\%')
        BEGIN

            SET @Resultado = (
                SELECT
                    @DBEngineLogin AS [DBEngineLogin],
                    @AgentLogin AS [AgentLogin]
                FOR XML PATH, ROOT('Instalacao_Usuario_Servico')
            )

        END
    


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 603

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Usuario_Servico>', 'Installation__Service_Account>')
            WHERE 
                Id_Verificacao = 603
        
        END


    END



    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o SQL Server está instalado em uma versão antiga do Windows Server ou se é versão "Pessoal" do Windows
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE 
            @VersaoWindows_ProductName VARCHAR(200),
            @VersaoWindows_CurrentVersion VARCHAR(200),
            @VersaoWindows_CurrentBuild VARCHAR(200),
            @VersaoWindows_Language VARCHAR(20)

        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', @value_name = 'ProductName', @value = @VersaoWindows_ProductName OUT
        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', @value_name = 'CurrentVersion', @value = @VersaoWindows_CurrentVersion OUT
        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion', @value_name = 'CurrentBuild', @value = @VersaoWindows_CurrentBuild OUT
        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SYSTEM\CurrentControlSet\Control\Nls\Language', @value_name = 'InstallLanguage', @value = @VersaoWindows_Language OUT
    
    
        SET @Resultado = NULL

    
        SET @Resultado = (
            SELECT 
                @VersaoWindows_ProductName AS [Product_Name],
                @VersaoWindows_CurrentBuild AS CurrentBuild, 
                @VersaoWindows_CurrentVersion AS CurrentVersion,
                @VersaoWindows_Language AS [Language]
            FOR XML PATH, ROOT('Instalacao_Versao_Windows')
        )
    

        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @VersaoWindows_ProductName LIKE '% Server %' AND (@VersaoWindows_ProductName LIKE '% Server 2016%' OR @VersaoWindows_ProductName LIKE '% Server 2019%') THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 604

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @VersaoWindows_ProductName LIKE '% Server %' AND (@VersaoWindows_ProductName LIKE '% Server 2016%' OR @VersaoWindows_ProductName LIKE '% Server 2019%') THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Versao_Windows>', 'Installation_Windows_Version>')
            WHERE 
                Id_Verificacao = 604
        
        END


    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se a versão do SQL Server ainda é suportada pela Microsoft
    ---------------------------------------------------------------------------------------------------------------

    DECLARE @Versoes_SQL_Server TABLE (
        [ProductName] VARCHAR(50),
        [ProductVersion] VARCHAR(100),
        [ProductLevel] VARCHAR(100),
        [Edition] VARCHAR(100),
        [EditionID] BIGINT,
        [EngineEdition] INT,
        [EngineEditionDescription] VARCHAR(100),
        [ProductBuild] INT,
        [ProductBuildType] VARCHAR(20),
        [ProductMajorVersion] INT,
        [ProductMinorVersion] INT,
        [ProductUpdateLevel] VARCHAR(100),
        [ProductUpdateReference] VARCHAR(100),
        [BuildClrVersion] VARCHAR(100),
        [LicenseType] VARCHAR(100),
        [ResourceVersion] VARCHAR(100)
    )

    
    INSERT INTO @Versoes_SQL_Server
    SELECT
        (CASE
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '8%' THEN 'SQL Server 2000'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '9%' THEN 'SQL Server 2005'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '10.0%' THEN 'SQL Server 2008'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '10.5%' THEN 'SQL Server 2008 R2'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '11%' THEN 'SQL Server 2012'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '12%' THEN 'SQL Server 2014'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '13%' THEN 'SQL Server 2016'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '14%' THEN 'SQL Server 2017'
            WHEN CONVERT(VARCHAR(128), SERVERPROPERTY ('ProductVersion')) LIKE '15%' THEN 'SQL Server 2019'
            ELSE 'Desconhecido'
        END) AS ProductName,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ProductVersion')) AS ProductVersion,
        CONVERT(VARCHAR(20), SERVERPROPERTY('ProductLevel')) AS ProductLevel,
        CONVERT(VARCHAR(100), SERVERPROPERTY('Edition')) AS Edition,
        CONVERT(BIGINT, SERVERPROPERTY('EditionID')) AS EditionID,
        CONVERT(INT, SERVERPROPERTY('EngineEdition')) AS EngineEdition,
        (CASE CONVERT(INT, SERVERPROPERTY('EngineEdition'))
            WHEN '1' THEN 'Personal ou Desktop Engine (Não disponível no SQL Server 2005 e em versões posteriores)'
            WHEN '2' THEN 'Standard (Retornada para Standard, Web e Business Intelligence)'
            WHEN '3' THEN 'Enterprise (Retornado para Evaluation, Developer e Enterprise)'
            WHEN '4' THEN 'Express (Retornada para Express, Express with Tools e Express com Advanced Services)'
            WHEN '5' THEN 'SQL Database'
            WHEN '6' THEN 'SQL Data Warehouse'
            WHEN '8' THEN 'Managed Instance'
        END) AS EngineEditionDescription,
        CONVERT(INT, SERVERPROPERTY('ProductBuild')) AS ProductBuild,
        CONVERT(VARCHAR(20), SERVERPROPERTY('ProductBuildType')) AS ProductBuildType,
        CONVERT(INT, SERVERPROPERTY('ProductMajorVersion')) AS ProductMajorVersion,
        CONVERT(INT, SERVERPROPERTY('ProductMinorVersion')) AS ProductMinorVersion,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ProductUpdateLevel')) AS ProductUpdateLevel,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ProductUpdateReference')) AS ProductUpdateReference,
        CONVERT(VARCHAR(100), SERVERPROPERTY('BuildClrVersion')) AS BuildClrVersion,
        CONVERT(VARCHAR(100), SERVERPROPERTY('LicenseType')) AS LicenseType,
        CONVERT(VARCHAR(100), SERVERPROPERTY('ResourceVersion')) AS ResourceVersion


    SET @Resultado = NULL

    
    SET @Resultado = (
        SELECT *
        FROM @Versoes_SQL_Server
        FOR XML PATH, ROOT('Instalacao_Versao_Nao_Suportada')
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN CONVERT(INT, SERVERPROPERTY('ProductMajorVersion')) >= 11 THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 605

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN CONVERT(INT, SERVERPROPERTY('ProductMajorVersion')) >= 11 THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Versao_Nao_Suportada>', 'Installation_Not_Supported_Version>')
        WHERE 
            Id_Verificacao = 605
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica a última atualização do SQL Server
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        DECLARE @Fl_Ole_Automation_Ativado BIT = (SELECT (CASE WHEN CAST([value] AS VARCHAR(MAX)) = '1' THEN 1 ELSE 0 END) FROM sys.configurations WHERE [name] = 'Ole Automation Procedures')
 
        IF (@Fl_Ole_Automation_Ativado = 0)
        BEGIN
 
            EXEC sp_configure 'show advanced options', 1
            RECONFIGURE WITH OVERRIDE
    
            EXEC sp_configure 'Ole Automation Procedures', 1
            RECONFIGURE WITH OVERRIDE
    
        END


    
        DECLARE 
            @obj INT,
            @Url VARCHAR(8000),
            @xml VARCHAR(MAX),
            @resposta VARCHAR(MAX)
        
        SET @Url = 'http://sqlserverbuilds.blogspot.com/'
 
        EXEC sys.sp_OACreate 'MSXML2.ServerXMLHTTP', @obj OUT
        EXEC sys.sp_OAMethod @obj, 'open', NULL, 'GET', @Url, false
        EXEC sys.sp_OAMethod @obj, 'send'
 
 
        DECLARE @xml_versao_sql TABLE (
            Ds_Dados VARCHAR(MAX)
        )
 
        INSERT INTO @xml_versao_sql(Ds_Dados)
        EXEC sys.sp_OAGetProperty @obj, 'responseText' --, @resposta OUT
    
    
        EXEC sys.sp_OADestroy @obj



        IF (@Fl_Ole_Automation_Ativado = 0)
        BEGIN
 
            EXEC sp_configure 'Ole Automation Procedures', 0
            RECONFIGURE WITH OVERRIDE
 
            EXEC sp_configure 'show advanced options', 0
            RECONFIGURE WITH OVERRIDE
 
        END
 
    

        DECLARE
            @Versao_SQL_Build VARCHAR(10)
    
        SET @Versao_SQL_Build = (CASE LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 2)
            WHEN '8.' THEN '2000'
            WHEN '9.' THEN '2005'
            WHEN '10' THEN (
                CASE
                    WHEN LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 4) = '10.5' THEN '2008 R2' 
                    WHEN LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 4) = '10.0' THEN '2008' 
                END)
            WHEN '11' THEN '2012'
            WHEN '12' THEN '2014'
            WHEN '13' THEN '2016'
            WHEN '14' THEN '2017'
            WHEN '15' THEN '2019'
            ELSE '2019'
        END)


        SELECT TOP 1 @resposta = Ds_Dados FROM @xml_versao_sql
 
    
        SET @xml = @resposta COLLATE SQL_Latin1_General_CP1251_CS_AS

        DECLARE
            @PosicaoInicialVersao INT,
            @PosicaoFinalVersao INT,
            @ExpressaoBuscar VARCHAR(100) = 'Microsoft SQL Server ' + @Versao_SQL_Build + ' Builds',
            @RetornoTabela VARCHAR(MAX),
            @dadosXML XML

        SET @PosicaoInicialVersao = CHARINDEX(@ExpressaoBuscar, @xml) + LEN(@ExpressaoBuscar) + 6
        SET @PosicaoFinalVersao = CHARINDEX('</table>', @xml, @PosicaoInicialVersao)
        SET @RetornoTabela = SUBSTRING(@xml, @PosicaoInicialVersao, @PosicaoFinalVersao - @PosicaoInicialVersao + 8)


        -- Corrigindo classes sem aspas duplas ("")
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' border=1 cellpadding=4 cellspacing=0 bordercolor="#CCCCCC" style="border-collapse:collapse"', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' target=_blank rel=nofollow', ' target="_blank" rel="nofollow"')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=h', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=lsp', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=cu', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=sp', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=rtm', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' width=580', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' width=125', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=lcu', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=cve', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=lrtm', '')
        SET @RetornoTabela = REPLACE(@RetornoTabela, ' class=beta', '')

        -- Corrigindo elementos não fechados corretamente
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<th', '</th><th')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<tr></th>', '<tr>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<th>Release Date</tr>', '<th>Release Date</th></tr>')

        SET @RetornoTabela = REPLACE(@RetornoTabela, '<td>', '</td><td>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<tr></td>', '<tr>')

        SET @RetornoTabela = REPLACE(@RetornoTabela, '</tr>', '</td></tr>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '</th></td>', '</th>')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '</td></td>', '</td>')

        -- Removendo elementos de entidades HTML
        SET @RetornoTabela = REPLACE(@RetornoTabela, '&nbsp;', ' ')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '&kbln', '&amp;kbln')
        SET @RetornoTabela = REPLACE(@RetornoTabela, '<br>', '<br/>')

		BEGIN TRY
	        SET @dadosXML = CONVERT(XML, @RetornoTabela)
		END TRY
		BEGIN CATCH
			SET @dadosXML = NULL
		END CATCH


        DECLARE @Atualizacoes_SQL_Server TABLE
        (
            [Ultimo_Build] VARCHAR(100),
            [Ultimo_Build_SQLSERVR.EXE] VARCHAR(100),
            [Versao_Arquivo] VARCHAR(100),
            [Q] VARCHAR(100),
            [KB] VARCHAR(100),
            [Descricao_KB] VARCHAR(100),
            [Lancamento_KB] VARCHAR(100),
            [Download_Ultimo_Build] VARCHAR(100)
        )

        SET @Resultado = NULL

		IF (@dadosXML IS NOT NULL)
		BEGIN
		
			INSERT INTO @Atualizacoes_SQL_Server
			SELECT
				@dadosXML.value('(//table/tr/td[1])[1]','varchar(100)') AS Ultimo_Build,
				@dadosXML.value('(//table/tr/td[2])[1]','varchar(100)') AS [Ultimo_Build_SQLSERVR.EXE],
				@dadosXML.value('(//table/tr/td[3])[1]','varchar(100)') AS Versao_Arquivo,
				@dadosXML.value('(//table/tr/td[4])[1]','varchar(100)') AS [Q],
				@dadosXML.value('(//table/tr/td[5])[1]','varchar(100)') AS KB,
				@dadosXML.value('(//table/tr/td[6]/a)[1]','varchar(100)') AS Descricao_KB,
				@dadosXML.value('(//table/tr/td[7])[1]','varchar(100)') AS Lancamento_KB,
				@dadosXML.value('(//table/tr/td[6]/a/@href)[1]','varchar(100)') AS Download_Ultimo_Build
		

			DECLARE 
				@Url_Ultima_Versao_SQL VARCHAR(500) = (SELECT TOP(1) Download_Ultimo_Build FROM @Atualizacoes_SQL_Server),
				@Ultimo_Build VARCHAR(100) = (SELECT TOP(1) Ultimo_Build FROM @Atualizacoes_SQL_Server)

		
			SET @Resultado = (
				SELECT *
				FROM @Atualizacoes_SQL_Server
				FOR XML PATH, ROOT('Instalacao_Atualizacoes_SQL')
			)
			
		END
		ELSE
		BEGIN
		
			IF (@language = 'en')
			BEGIN
			
				SET @Resultado = (
					SELECT 'Could not parse most recent version information from http://sqlserverbuilds.blogspot.com/'
					FOR XML PATH, ROOT('Instalacao_Atualizacoes_SQL')
				)
				
			END
			
		END

        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN CONVERT(VARCHAR(100), SERVERPROPERTY('ProductVersion')) >= @Ultimo_Build THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Referencia = @Url_Ultima_Versao_SQL,
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 606

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN CONVERT(VARCHAR(100), SERVERPROPERTY('ProductVersion')) >= @Ultimo_Build THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Referencia = @Url_Ultima_Versao_SQL,
                Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Atualizacoes_SQL>', 'Installation_SQL_Updates>')
            WHERE 
                Id_Verificacao = 606
        
        END
    

    END


    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem bases de dados "públicas" na instância
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    
    SET @Resultado = (
        SELECT 
            [name] AS 'Database/@name',
            database_id AS 'Database/@database_id',
            [compatibility_level] AS 'Database/@compatibility_level',
            [state_desc] AS 'Database/@state_desc',
            recovery_model_desc AS 'Database/@recovery_model_desc',
            page_verify_option_desc AS 'Database/@page_verify_option_desc'
        FROM
            sys.databases
        WHERE
            [name] IN ('pub', 'Northwind', 'AdventureWorks', 'AdventureWorksLT', 'AdventureWorksDW', 'WideWorldImporters', 'WideWorldImportersDW')
        FOR XML PATH(''), ROOT('Instalacao_Databases_Publicas'), TYPE
    )


    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 607

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Databases_Publicas>', 'Installation_Public_Databases>')
        WHERE 
            Id_Verificacao = 607
        
    END
    
    
    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se existem bases de dados "públicas" na instância
    ---------------------------------------------------------------------------------------------------------------

    SET @Resultado = NULL

    
    SET @Resultado = (
        SELECT DISTINCT 
            net_transport 
        FROM 
            sys.dm_exec_connections 
        WHERE 
            net_transport NOT IN ('Session', 'TCP', 'Shared Memory')
        FOR XML PATH, ROOT('Instalacao_Protocolos_de_Rede')
    )
    

    IF (@language = 'pt')
    BEGIN
        
        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
            Ds_Detalhes = @Resultado
        WHERE 
            Id_Verificacao = 608

    END
    ELSE IF (@language = 'en')
    BEGIN

        UPDATE #Resultado
        SET 
            Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
            Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Protocolos_de_Rede>', 'Installation_Network_Protocols>')
        WHERE 
            Id_Verificacao = 608
        
    END

    

    ---------------------------------------------------------------------------------------------------------------
    -- Verifica se o Firewall do Windows está ativado
    ---------------------------------------------------------------------------------------------------------------

    IF (@IsAmazonRDS = 0)
    BEGIN

        
        DECLARE @Windows_Firewall INT

        EXEC master.dbo.xp_regread @rootkey = 'HKEY_LOCAL_MACHINE', @key = 'SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile', @value_name = 'EnableFirewall', @value = @Windows_Firewall OUT
    
    
        SET @Resultado = NULL


        IF (@Windows_Firewall = 0)
        BEGIN
    
            SET @Resultado = (
                SELECT
                    'SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile' AS [Chave],
                    @Windows_Firewall AS [EnableFirewall]
                FOR XML PATH, ROOT('Instalacao_Windows_Firewall')
            )

        END


        IF (@language = 'pt')
        BEGIN
        
            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possível problema encontrado' END),
                Ds_Detalhes = @Resultado
            WHERE 
                Id_Verificacao = 609

        END
        ELSE IF (@language = 'en')
        BEGIN

            UPDATE #Resultado
            SET 
                Ds_Resultado = (CASE WHEN @Resultado IS NULL THEN 'OK' ELSE 'Possible issue found' END),
                Ds_Detalhes = REPLACE(CAST(@Resultado AS VARCHAR(MAX)), 'Instalacao_Windows_Firewall>', 'Installation_Windows_Firewall>')
            WHERE 
                Id_Verificacao = 609
        
        END

        
    END


        
    ---------------------------------------------------------------------------------------------------------------
    -- Mostra os resultados
    ---------------------------------------------------------------------------------------------------------------
    
    IF (@language = 'en')
    BEGIN

        SELECT 
            Id_Verificacao AS [Code],
            Ds_Categoria AS [Category],
            Ds_Titulo AS [Title],
            Ds_Resultado AS [Result],
            Ds_Descricao AS [How this can be an Issue],
            Ds_Verificacao AS [Technical explanation],
            Ds_Sugestao AS [How to Fix],
            Ds_Detalhes AS [Result Details],
            CONVERT(XML, Ds_Referencia) AS [External Reference]
        FROM 
            #Resultado

    END
    ELSE IF (@language = 'pt')
    BEGIN
        
        SELECT 
            Id_Verificacao AS [Código],
            Ds_Categoria AS [Categoria],
            Ds_Titulo AS [O que é verificado],
            Ds_Resultado AS [Avaliação],
            Ds_Descricao AS [Descrição do Problema],
            Ds_Verificacao AS [Detalhamento da Verificação],
            Ds_Sugestao AS [Sugestão de Correção],
            Ds_Detalhes AS [Resultados da Validação],
            CONVERT(XML, Ds_Referencia) AS [URL de Referência]
        FROM 
            #Resultado

    END
 

END



-- EXEC dbo.stpSecurity_Checklist

GO
