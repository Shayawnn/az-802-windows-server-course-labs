@{
    Severity = @('Error','Warning')
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingInvokeExpression',
        'PSAvoidUsingPlainTextForPassword',
        'PSUseApprovedVerbs',
        'PSUseCmdletCorrectly'
    )
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )
}
