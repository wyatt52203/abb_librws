MODULE motion
    VAR bool left_to_right;
    
    ! interrupt identifiers
    VAR intnum intno1;
    VAR intnum intno2;

    ! web params
    PERS num spd;
    PERS num int;
    PERS num lft;
    PERS num rgt;
    PERS num upr;
    PERS num lwr;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS bool go;
    PERS bool play;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num y;
    PERS num z;
    
    
    
    PROC main()

        IDelete intno1;
        CONNECT intno1 WITH wait_trap;
        ISignalDO MyPauseSignal, 1, intno1;

        IDelete intno2;
        CONNECT intno2 WITH reset_trap;
        ISignalDO MyResetSignal, 1, intno2;

        ConfL \Off;

        WHILE TRUE DO
            ! Wait for persistent variable signal
            WaitUntil go;

            ! Set Motion Parameters
            AccSet acc, jrk \FinePointRamp:=dac;
            left_to_right := TRUE;
            z := upr;

            WHILE z >= lwr DO
                IF left_to_right THEN
                    y := lft;
                ELSE
                    y := rgt;
                ENDIF

                IF go MoveL [[350, y, z], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;

                IF left_to_right THEN
                    y := rgt;
                ELSE
                    y := lft;
                ENDIF

                IF go MoveL [[350, y, z], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;

                z := z - int;
                left_to_right := NOT left_to_right;
            ENDWHILE

            ! Reset go to wait for another signal
            go := FALSE;
            
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            ! TRYNEXT;
    ENDPROC

    TRAP wait_trap
        StopMove;
        StorePath;
        
        WaitUntil play;
        SetDO MyPauseSignal, 0;

        RestoPath;
        StartMove;
    ENDTRAP

    TRAP reset_trap
        StopMove;
        ClearPath;
        StartMove;
        MoveJ [[350, lft, upr], [1,0,0,0], [-1,0,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], v400, fine, tool0;

        go := FALSE;
        SetDO MyResetSignal, 0;

        ExitCycle;
    ENDTRAP

    
    
ENDMODULE



