function [ FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, dynareOBC ] = InsertGlobalEquations( FileLines, ToInsertBeforeModel, ToInsertInModelAtEnd, ToInsertInShocks, ToInsertInInitVal, MaxArgValues, CurrentNumParams, CurrentNumVar, dynareOBC )
    
    ns = dynareOBC.NumberOfMax;
    nSVASC = size( dynareOBC.StateVariableAndShockCombinations, 1 );
    
    dynareOBC.ParameterIndices_StateVariableAndShockCombinations = zeros( nSVASC, ns );

    dynareOBC.VarIndices_ZeroLowerBounded = zeros( 1, ns );
    dynareOBC.VarIndices_RawZeroLowerBounded = zeros( 1, ns );
    dynareOBC.VarIndices_StateVariableAndShockCombinations = zeros( nSVASC, 1 );
    
    CombinationNames = cell( nSVASC, 1 );
       
    for k = 1 : nSVASC
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_StateVariableAndShockCombinations( k ) = CurrentNumVar;
        StateVariableAndShockCombination = dynareOBC.StateVariableAndShockCombinations( k, : );
        SVASCEquation = '=1';
        SVASCInit = '=1';
        CombinationName = '1';
        for l = 1 : length( StateVariableAndShockCombination )
            if StateVariableAndShockCombination( l ) > 0
                varCurrent = dynareOBC.StateVariablesAndShocks{ l };
                for m = 1 : StateVariableAndShockCombination( l )
                    SVASCEquation = [ SVASCEquation '*' varCurrent ];
                    varCurrentNow = regexprep( varCurrent, '\([+-]?\d+\)', '' );
                    CombinationName = [ CombinationName 'T' varCurrentNow ];
                    SVASCInit = [ SVASCInit '*' varCurrentNow ];
                end
            end
        end
        CombinationNames{k} = CombinationName;
        SVASCVarName = [ 'dynareOBCSVASC_' CombinationName ];
        ToInsertBeforeModel{ end + 1 } = [ 'var ' SVASCVarName ';' ];
        ToInsertInModelAtEnd{ end + 1 } = [ SVASCVarName SVASCEquation ';' ];
        ToInsertInInitVal{ end + 1 } = [ SVASCVarName SVASCInit ';' ];
    end
    
    for i = 1 : ns
        string_i = int2str( i );
        parametersString = '';
        parameterValues = { };
        if MaxArgValues( i, 1 ) > MaxArgValues( i, 2 )
            MaxLetter = 'A';
            MinLetter = 'B';
            SteadyStateBoundedVar = MaxArgValues( i, 1 ) - MaxArgValues( i, 2 );
        else
            MaxLetter = 'B';
            MinLetter = 'A';
            SteadyStateBoundedVar = MaxArgValues( i, 2 ) - MaxArgValues( i, 1 );
        end
        
        BoundedVarName = [ 'dynareOBCZeroLowerBounded' string_i ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_ZeroLowerBounded( i ) = CurrentNumVar;
        
        RawBoundedVarName = [ 'dynareOBCRawZeroLowerBounded' string_i ];
        CurrentNumVar = CurrentNumVar + 1;
        dynareOBC.VarIndices_RawZeroLowerBounded( i ) = CurrentNumVar;

        ZLBEquation = [ BoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ];

        for k = 1 : nSVASC
            parameterName = [ 'dynareOBCGlobalParam' string_i '_' CombinationNames{k} ];
            parametersString = [ parametersString ' ' parameterName ];
            CurrentNumParams = CurrentNumParams + 1;
            dynareOBC.ParameterIndices_StateVariableAndShockCombinations( k, i ) = CurrentNumParams;
            parameterValues{ end + 1 } = [ parameterName '=0;' ];
            ZLBEquation = [ ZLBEquation '+' parameterName '*dynareOBCSVASC_' CombinationNames{k} ];
        end
        
        ToInsertInModelAtEnd{ end + 1 } = [ ZLBEquation ';' ]; %#ok<*AGROW>
        ToInsertInModelAtEnd{ end + 1 } = [ RawBoundedVarName '=dynareOBCMaxArg' MaxLetter string_i '-dynareOBCMaxArg' MinLetter string_i ';' ]; %#ok<*AGROW>
        FileLines{ dynareOBC.MaxFuncIndices( i ) } = [ '#dynareOBCMaxFunc' string_i '=dynareOBCMaxArg' MinLetter string_i '+' BoundedVarName ';' ];
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e;', BoundedVarName, SteadyStateBoundedVar );
        ToInsertInInitVal{ end + 1 } = sprintf( '%s=%.17e;', RawBoundedVarName, SteadyStateBoundedVar );

        varString = [ 'var ' BoundedVarName ' ' RawBoundedVarName ';' ];
        if isempty( parametersString )
            ToInsertBeforeModel = [ ToInsertBeforeModel { varString } ];
        else
            parametersString = [ 'parameters' parametersString ';' ];
            ToInsertBeforeModel = [ ToInsertBeforeModel { parametersString } parameterValues { varString } ];
        end
    end
    
end
