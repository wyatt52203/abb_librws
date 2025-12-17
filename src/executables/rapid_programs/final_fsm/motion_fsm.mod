MODULE motion
    ! interrupt identifiers
    VAR intnum intno1;
    VAR intnum intno2;
    VAR intnum intno3;
    VAR intnum intno4;

    ! variables for calculation
    VAR jointtarget jt;
    VAR robtarget current_pos;

    ! global params
    PERS bool go;
    PERS num spd;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num x_target;
    PERS num y_target;
    PERS num z_target;
    PERS num x_read;
    PERS num y_read;
    PERS num z_read;

    PERS bool udp_channel_live;
    PERS bool fsm_channels_live;

    PERS num state := 0;
    ! STATE DEFINITION
    ! 0 = IDLE
    ! 1 = RUNNING
    ! 2 = PAUSED
    ! 3 = ABORTED
    
    PERS bool motion_complete;

    PERS bool reset_params := TRUE;

    PROC ReadPos()
        
        ! Wait for robot to fully stop
        ! WaitRob \ZeroSpeed;

        jt := CjointT();

        ! Calculate robtarget from jointtarget
        current_pos := CalcRobT(jt, tool0);

        x_read := current_pos.trans.x;
        y_read := current_pos.trans.y;
        z_read := current_pos.trans.z;

    ENDPROC


    PROC main()
        ! Reset interrupts
        SetDO MyResetSignal, 0;
        SetDO MyEmergencyStopSignal, 0;
        SetDO MyPauseSignal, 0;
        SetDO MyContinueSignal, 0;

        IDelete intno1;
        CONNECT intno1 WITH pause_trap;
        ISignalDO MyPauseSignal, 1, intno1;

        IDelete intno2;
        CONNECT intno2 WITH reset_trap;
        ISignalDO MyResetSignal, 1, intno2;

        IDelete intno3;
        CONNECT intno3 WITH continue_trap;
        ISignalDO MyContinueSignal, 1, intno3;

        IDelete intno4;
        CONNECT intno4 WITH emergency_trap;
        ISignalDO MyEmergencyStopSignal, 1, intno4;

        ConfL \Off;
        go := FALSE;
        
        udp_channel_live := FALSE;
        fsm_channels_live := TRUE;

        IF reset_params THEN
            spd := 800;
            acc := 10000;
            jrk := 100;
            dac := 10000;
            zone := [TRUE, 0, 0, 0, 0, 0, 0];
            speed := [800, 1000, 5000, 1000];
            x_target := 300;
            y_target := -450;
            z_target := 700;
        ENDIF

        reset_params := TRUE;        

        WHILE TRUE DO
            ! Update Globals from robot
            ReadPos;

            IF state = 0 THEN

                IF go THEN
                    ! Set state to running while in motion
                    go := FALSE;
                    state := 1;

                    ! Set Motion Parameters
                    AccSet 100, jrk;
                    PathAccLim TRUE\AccMax := (acc/1000), TRUE\DecelMax := (dac/1000);
                    
                    MoveL [[x_target, y_target, z_target], [0,1,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, zone, tool0;
                ENDIF
            
            ENDIF

            ! If in running state
            IF state = 1 THEN
                ! Wait for robot to fully stop, set to idle
                WaitRob \ZeroSpeed;

                motion_complete := TRUE;
                state := 0;
                
            ENDIF
            
            ! Nothing to do in states 2 (paused) and 3 (estopped)
            
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            ! TRYNEXT;
    ENDPROC

    TRAP emergency_trap
        SetDO MyEmergencyStopSignal, 0;
        if state <> 3 THEN
            StopMove;
            ClearPath;
            state := 3;
        ENDIF
    ENDTRAP

    TRAP pause_trap
        SetDO MyPauseSignal, 0;
        IF (state <> 2 AND state <> 3) THEN    
            StopMove;
            StorePath;
            go := FALSE;
            state := 2;
        ENDIF
    ENDTRAP

    TRAP continue_trap
        SetDO MyContinueSignal, 0;
        IF state = 2 THEN
            RestoPath;
            StartMove;
            state := 1;
        ENDIF
    ENDTRAP

    TRAP reset_trap
        SetDO MyResetSignal, 0;
        IF state <> 3 THEN
            StopMove;
            ClearPath;
            StartMove;

            ExitCycle;
        ENDIF
    ENDTRAP

    
    
ENDMODULE