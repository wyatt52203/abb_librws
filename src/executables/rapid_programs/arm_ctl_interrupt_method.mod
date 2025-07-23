MODULE arm_ctl_interrupt_method
    VAR robtarget current_pos;
    VAR intnum intno2;
    VAR intnum intno3;
    VAR intnum intno4;

    VAR triggdata trigg1;

    VAR jointtarget jt;

    VAR bool calibrated;
    VAR num cur_error;

    VAR string print_msg;

    VAR num temp1;
    VAR num temp2;

    VAR num y_dist;
    VAR num z_dist;
    VAR num interrupt_dist;

    VAR num prev_y_target;
    VAR num prev_z_target;

    VAR num y_target;
    VAR num z_target;

    ! PERS Params
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num move_arm;
    
    TRAP reset_trap
        StopMove;
        ClearPath;
        StartMove;
        MoveJ [[350, -600, 850], [1,0,0,0], [-1,0,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], v400, fine, tool0 \WObj:=wobj0;
        CustomCalibrate;

        y_target := -600;
        z_target := 850;

        go := FALSE;
        SetDO MyResetSignal, 0;

        ExitCycle;
    ENDTRAP

    TRAP move_to_target_trap

        ! save location to move to within this task
        temp1 := y_target;
        temp2 := z_target;

        y_dist := (y_target - prev_y_target);
        z_dist := (z_target - prev_z_target);

        TriggL [[350, y_target, z_target], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, trigg1, z100, tool0;
        
        ! save location that was moved to persisent variable
        prev_y_target := temp1;
        prev_z_target := temp2;
    ENDTRAP

    TRAP test_trap

        ! save location to move to within this task
        temp1 := y_target;
        temp2 := z_target;

        y_dist := (y_target - prev_y_target);
        z_dist := (z_target - prev_z_target);

        MoveL [[350, y_target, z_target], [1,0,0,0], [-3,-3,-3,-3], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, z100, tool0;
        
        ! save location that was moved to persisent variable
        prev_y_target := temp1;
        prev_z_target := temp2;

        cur_error := Abs(prev_y_target - y_target) + Abs(prev_z_target - z_target);

        IF (cur_error > 0.1) THEN
            TPWrite("movin 2");
            ! move towards target if there is any error

            move_arm := move_arm + 1;
        ELSE
            TPWrite("made it");
        ENDIF
    ENDTRAP

    PROC CustomCalibrate()
        
        ! Wait for robot to fully stop
        WaitRob \ZeroSpeed;

        jt := CjointT();

        ! Calculate robtarget from jointtarget
        current_pos := CalcRobT(jt, tool0);

        y := current_pos.trans.y;
        z := current_pos.trans.z;

        prev_y_target := y;
        prev_z_target := z;

    ENDPROC

    
    PROC main()

        IDelete intno2;
        CONNECT intno2 WITH reset_trap;
        ISignalDO MyResetSignal, 1, intno2;

        move_arm := 0;

        IDelete intno3;
        CONNECT intno3 WITH move_to_target_trap;
        IPers move_arm, intno3;

        IDelete intno4;
        CONNECT intno4 WITH test_trap;

        interrupt_dist := 0.1*Sqrt(Pow(y_dist, 2) + Pow(z_dist, 2));
        TriggInt trigg1, 1, intno4;

        ConfL \Off;

        zone := z100;
        speed := v80;
        AccSet 100, 100 \FinePointRamp:=100;

        CustomCalibrate;

        y_target := y;
        z_target := z;
        calibrated := TRUE;

        WHILE TRUE DO

            WaitTime 0.01;

            ! Enforce Y bounds
            IF y_target > 600 THEN
                y_target := 600;
            ELSEIF y_target < -600 THEN
                y_target := -600;
            ENDIF

            ! Enforce Z bounds [250, 850]
            IF z_target > 850 THEN
                z_target := 850;
            ELSEIF z_target < 250 THEN
                z_target := 250;
            ENDIF

            CustomCalibrate;

            cur_error := Abs(y - y_target) + Abs(z - z_target);

            IF (cur_error > 15) THEN
                TPWrite("movin");
                ! move towards target if there is any error

                move_arm := move_arm + 1;
            ENDIF

        ENDWHILE        
        
    ENDPROC
    
ENDMODULE
