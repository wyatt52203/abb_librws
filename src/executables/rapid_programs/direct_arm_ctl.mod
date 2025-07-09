MODULE direct_arm_ctl
    VAR num move_distance := 60;  ! Default move distance
    VAR robtarget current_pos;
    VAR intnum intno2;

    VAR num j1;
    VAR num j2;
    VAR num j3;
    VAR num j4;
    VAR num j5;
    VAR num j6;
    VAR jointtarget jt;

    ! Web Params
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num mdr;
    PERS bool cb;
    PERS num y;
    PERS num z;
    
    TRAP reset_trap
        StopMove;
        ClearPath;
        StartMove;
        MoveJ [[350, -600, 850], [1,0,0,0], [-1,0,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], v400, fine, tool0 \WObj:=wobj0;
        Calibrate;

        go := FALSE;
        SetDO MyResetSignal, 0;

        ExitCycle;
    ENDTRAP

    PROC Calibrate()
        
        ! Wait for robot to fully stop
        WaitRob \ZeroSpeed;

        jt := CjointT();

        ! Calculate robtarget from jointtarget
        current_pos := CalcRobT(jt, tool0);

        y := current_pos.trans.y;
        z := current_pos.trans.z;

    ENDPROC

    
    PROC main()

        IDelete intno2;
        CONNECT intno2 WITH reset_trap;
        ISignalDO MyResetSignal, 1, intno2;

        ConfL \Off;

        zone := z200;
        speed := v1000;
        AccSet 50, 50 \FinePointRamp:=50;

        Calibrate;

        WHILE TRUE DO

            if (NOT go) THEN
                ! Wait for persistent variable signal
                WaitUntil go;

                if cb THEN
                    Calibrate;
                    cb := FALSE;
                    mdr := -5;
                ENDIF
            ENDIF

            TEST mdr
                CASE -1:
                    y := y + move_distance;
                CASE -2:
                    y := y - move_distance;
                CASE -3:
                    z := z + move_distance;
                CASE -4:
                    z := z - move_distance;
                DEFAULT:
                    IF mdr > 0 THEN
                        move_distance := mdr;
                    ENDIF
            ENDTEST

            ! Enforce Y bounds [-600, 600]
            IF y > 600 THEN
                y := 600;
            ELSEIF y < -600 THEN
                y := -600;
            ENDIF

            ! Enforce Z bounds [100, 700]
            IF z > 850 THEN
                z := 850;
            ELSEIF z < 250 THEN
                z := 250;
            ENDIF
            
            go := FALSE;

            ! Perform movement
            MoveL [[350, y, z], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
        ENDWHILE        
        
    ENDPROC
    
ENDMODULE



