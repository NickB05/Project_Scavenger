/*
"Proyecto Scavenger" - TranZit / Die Rise / Buried
v1.3

Creado por: NickB_05

Este script te permite llevar todas las piezas construibles de los mapas
del grupo Victis, de forma similar al sistema de transporte de piezas
de Mob, Origins y BO3.

Mi objetivo es que el sistema de transporte de piezas sea lo más parecido
posible al de Mob y Origins, incluyendo elementos de interfaz similares
y mostrando las piezas en la tabla de puntuaciones; por ahora no es así,
ya que sigo aprendiendo a implementar la interfaz, pero al menos el
concepto es 100% fiel al original.

Las únicas piezas que no se pueden llevar todas a la vez son la llave del ascensor,
la llave de la prisión, el licor, los caramelos y las tizas de armas; esto es
principalmente para mantener las mecánicas y... porque tengo algunas ideas
para la llave del ascensor... ¡disfruta del script!

AVISO: Si vas a utilizar este script para otro proyecto, por favor
da crédito a mi trabajo, ya que tardé al menos un mes en terminarlo.

v1.1 Correcciones realizadas por: SyntaXError
v1.2 Correcciones realizadas por: NickB_05
v1.3 Correcciones para multijugador realizadas por: NickB_05
*/

#include maps\mp\zombies\_zm_buildables;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_utility;
#include maps\mp\gametypes_zm\_hud_util;
#include maps\mp\_utility;

#define MC_BUILD_RADIUS_SQ 7000 // distancia horizontal (X/Y) para la mayoría de las áreas edificables
#define MC_BUILD_RADIUS_SQ_TIGHT 2500 // Escotilla/escalera/arado: colocados más juntos para evitar pisar la zona de reparación de la ventana u otros elementos cercanos
#define MC_HEIGHT_TOLERANCE 82 // Diferencia de altura máxima permitida (Z): filtra los distintos niveles (generalmente separados por 128 unidades o más) sin interferir con la construcción estándar
#define MC_DEFAULT_BUILD_TIME 3000 // ms, se utiliza si el stub no trae su propio tiempo de uso

init()
{
    map = getdvar( "mapname" );

    if ( map != "zm_transit" && map != "zm_highrise" && map != "zm_buried" )
        return;

    if ( map == "zm_buried" )
    {
        func = getfunction( "maps/mp/zombies/_zm_buildables_pooled", "pooledbuildable_stub_for_piece" );
        if ( isdefined( func ) )
        {
            replacefunc( func, ::custom_pooledbuildable_stub_for_piece );
        }
    }

    level.mc_is_buried = ( map == "zm_buried" );

    level.mc_have = [];

    level.mc_debug = 0;
    if ( getdvar( "mc_debug" ) == "1" )
        level.mc_debug = 1;

    level.mc_gated_buildables = [];
    level.mc_gated_buildables["jetgun_zm"] = 1;
    level.mc_gated_buildables["turbine"] = 1;
    level.mc_gated_buildables["riotshield_zm"] = 1;
    level.mc_gated_buildables["turret"] = 1;
    level.mc_gated_buildables["electric_trap"] = 1;
    level.mc_gated_buildables["powerswitch"] = 1;
    level.mc_gated_buildables["pap"] = 1;
    level.mc_gated_buildables["sq_common"] = 1;
    level.mc_gated_buildables["springpad_zm"] = 1; 
    level.mc_gated_buildables["slipgun_zm"] = 1;
    level.mc_gated_buildables["headchopper_zm"] = 1;
    level.mc_gated_buildables["subwoofer_zm"] = 1;
    level.mc_gated_buildables["buried_sq_bt_m_tower"] = 1;
    level.mc_gated_buildables["buried_sq_bt_r_tower"] = 1;
    level.mc_immediate_buildables = [];
    level.mc_immediate_buildables["cattlecatcher"] = 1;
    level.mc_immediate_buildables["bushatch"] = 1;
    level.mc_immediate_buildables["dinerhatch"] = 1;
    level.mc_immediate_buildables["busladder"] = 1;

    level thread on_player_connect();
    level thread mc_debug_print_names();
    level thread mc_setup_custom_prompts();
}

mc_debug_print_names()
{
    level waittill( "buildables_setup" );

    if ( !level.mc_debug )
        return;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) )
            continue;

        name = stub.buildablezone.buildable_name;
        gated = isdefined( level.mc_gated_buildables[name] );
        immediate = isdefined( level.mc_immediate_buildables[name] );
        println( "[mc_debug] buildable_name = " + name + "  (gated=" + gated + ", immediate=" + immediate + ")" );
    }
}

mc_display_name( name )
{
    switch ( name )
    {
        case "riotshield_zm":
            return "Escudo Zombi";
        case "jetgun_zm":
            return "Jet Gun";
        case "turbine":
            return "Turbina";
        case "turret":
            return "Torreta";
        case "electric_trap":
            return "Trampa Electrica";
        case "powerswitch":
            return "Interruptor de Energia";
        case "pap":
            return "Potenciadora";
        case "sq_common":
            return "Tarjeta-Nav";
        case "springpad_zm":
            return "Trampolin de Aire";
        case "slipgun_zm":
            return "Esiquificador";
        case "headchopper_zm":
            return "Corta Cabezas";
        case "subwoofer_zm":
        case "subwoofer":
            return "Resonador";
        case "buried_sq_bt_m_tower":
            return "Horcas";
        case "buried_sq_bt_r_tower":
            return "Guillotinas";
        case "cattlecatcher":
            return "Parachoques";
        case "bushatch":
            return "Escotilla del Bus";
        case "dinerhatch":
            return "Escotilla de Cafeteria";
        case "busladder":
            return "Escalera del Bus";
    }

    return name;
}

mc_representative_icon( name )
{
    switch ( name )
    {
        case "riotshield_zm":
            return "riotshield_zm_icon";
        case "jetgun_zm":
            return "jetgun_zm_icon";
        case "turbine":
            return "turbine_zm_icon";
        case "turret":
            return "turret_zm_icon";
        case "electric_trap":
            return "etrap_zm_icon";
        case "powerswitch":
            return "zm_hud_icon_panel";
        case "pap":
            return "zm_hud_icon_papbody";
        case "sq_common":
            return "zm_hud_icon_sq_powerbox";
        case "springpad_zm":
            return "zom_hud_trample_steam_complete";
        case "slipgun_zm":
            return "zom_hud_icon_buildable_slip_ext";
        case "headchopper_zm":
            return "zom_hud_icon_buildable_chop_a";
        case "subwoofer_zm":
        case "subwoofer":
            return "zom_hud_icon_buildable_woof_speaker";
        case "buried_sq_bt_m_tower":
            return "zm_hud_icon_battery";
        case "buried_sq_bt_r_tower":
            return "zm_hud_icon_sq_meteor";
        case "cattlecatcher":
            return "zm_hud_icon_plow";
        case "bushatch":
            return "zm_hud_icon_hatch";
        case "dinerhatch":
            return "zm_hud_icon_hatch";
        case "busladder":
            return "zm_hud_icon_ladder";
    }

    return undefined;
}

mc_show_piece_notify( display_name, hud_icon, progress_text )
{
    self endon( "disconnect" );

    if ( isdefined( self.mc_notify_icon ) )
        self.mc_notify_icon destroy();

    if ( isdefined( self.mc_notify_text ) )
        self.mc_notify_text destroy();

    icon = newclienthudelem( self );
    icon.horzalign = "left";
    icon.vertalign = "top";
    icon.alignx = "right";
    icon.aligny = "top";
    icon.x = -12;
    icon.y = -23;
    icon.alpha = 1;

    if ( isdefined( hud_icon ) )
        icon setshader( hud_icon, 20, 20 );

    text = newclienthudelem( self );
    text.horzalign = "left";
    text.vertalign = "top";
    text.alignx = "left";
    text.aligny = "top";
    text.x = -8;
    text.y = -23;
    text.fontscale = 1.3;
    text.alpha = 1;
    text settext( display_name + " (" + progress_text + ")" );

    self.mc_notify_icon = icon;
    self.mc_notify_text = text;

    icon thread mc_fade_and_destroy( 2.5 );
    text thread mc_fade_and_destroy( 2.5 );
}

mc_fade_and_destroy( delay )
{
    self endon( "death" );
    wait delay;

    if ( !isdefined( self ) )
        return;

    self fadeovertime( 0.5 );
    self.alpha = 0;
    wait 0.5;

    if ( isdefined( self ) )
        self destroy();
}

mc_is_ours( name )
{
    return isdefined( level.mc_gated_buildables[name] ) || isdefined( level.mc_immediate_buildables[name] );
}

mc_is_gated( name )
{
    return isdefined( level.mc_gated_buildables[name] );
}

mc_in_range( origin, target, radius_sq )
{
    if ( distance2dsquared( origin, target ) >= radius_sq )
        return false;

    zdiff = origin[2] - target[2];

    if ( zdiff < 0 )
        zdiff = zdiff * -1;

    if ( zdiff > MC_HEIGHT_TOLERANCE )
        return false;

    return true;
}

mc_build_radius_sq( name )
{
    switch ( name )
    {
        case "bushatch":
        case "dinerhatch":
        case "busladder":
        case "cattlecatcher":
            return MC_BUILD_RADIUS_SQ_TIGHT;
    }

    return MC_BUILD_RADIUS_SQ;
}

mc_setup_custom_prompts()
{
    level waittill( "buildables_setup" );

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) )
            continue;

        if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        stub.mc_original_prompt = stub.custom_buildablestub_update_prompt;
        stub.custom_buildablestub_update_prompt = ::mc_custom_prompt;
    }
}

mc_buried_find_ready_target()
{
    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( can_attempt )
            return stub;
    }

    return undefined;
}

mc_custom_prompt( player )
{
    if ( isdefined( self.built ) && self.built )
        return true;

    if ( isdefined( self.mc_original_prompt ) && !( self [[ self.mc_original_prompt ]]( player ) ) )
        return false;

    if ( !isdefined( self.buildablezone ) )
        return true;

    zone = self.buildablezone;

    if ( !mc_is_ours( zone.buildable_name ) )
        return true;

    deliverable = player mc_get_deliverable_pieces( zone );
    ready = false;

    if ( mc_is_gated( zone.buildable_name ) )
        ready = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
    else
        ready = deliverable.size > 0;

    display_name = zone.buildable_name;

    if ( !ready && level.mc_is_buried )
    {
        target = player mc_buried_find_ready_target();

        if ( isdefined( target ) )
        {
            ready = true;
            display_name = target.buildablezone.buildable_name;
        }
    }

    if ( ready )
    {
        if ( isdefined( level.zombie_buildables[self.equipname] ) && isdefined( level.zombie_buildables[self.equipname].hint ) )
            self.hint_string = level.zombie_buildables[self.equipname].hint;
			
        self.cursor_hint = "HINT_NOICON";
        return false;
    }

    return true;
}

on_player_connect()
{
    level endon( "end_game" );

    while ( true )
    {
        level waittill( "connected", player );
        player thread player_collect_and_build();
    }
}

mc_get_stub_origin( stub )
{
    if ( isdefined( stub.originfunc ) )
        return stub [[ stub.originfunc ]]();

    return stub.origin;
}

mc_count_remaining( zone )
{
    remaining = 0;

    for ( i = 0; i < zone.pieces.size; i++ )
    {
        if ( !( isdefined( zone.pieces[i].built ) && zone.pieces[i].built ) )
            remaining++;
    }

    return remaining;
}

mc_piece_key( piece )
{
    return piece.buildablename + "|" + piece.modelname;
}

mc_get_deliverable_pieces( zone )
{
    result = [];
    used = [];

    for ( i = 0; i < zone.pieces.size; i++ )
    {
        if ( isdefined( zone.pieces[i].built ) && zone.pieces[i].built )
            continue;

        key = mc_piece_key( zone.pieces[i] );

        pool = 0;
        if ( isdefined( level.mc_have[key] ) )
            pool = level.mc_have[key];

        consumed = 0;
        if ( isdefined( used[key] ) )
            consumed = used[key];

        if ( pool - consumed > 0 )
        {
            result[result.size] = zone.pieces[i];
            used[key] = consumed + 1;
        }
    }

    return result;
}

player_collect_and_build()
{
    self endon( "disconnect" );
    level waittill( "buildables_setup" );

    self thread mc_collect_loop();
    self thread mc_deliver_loop();
}

mc_collect_loop()
{
    self endon( "disconnect" );

    while ( true )
    {
        self mc_try_collect();
        wait 0.05;
    }
}

mc_deliver_loop()
{
    self endon( "disconnect" );

    while ( true )
    {
        if ( level.mc_is_buried )
            self mc_try_deliver_buried();
        else
            self mc_try_deliver_default();

        wait 0.1;
    }
}

mc_try_collect()
{
    held_pieces = self player_get_buildable_pieces();

    if ( held_pieces.size == 0 )
        return;

    foreach ( held in held_pieces )
    {
        if ( !isdefined( held ) )
            continue;

        candidates = [];

        foreach ( stub in level.buildable_stubs )
        {
            if ( !isdefined( stub.buildablezone ) || !isdefined( stub.buildablezone.pieces ) )
                continue;

            if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
                continue;

            if ( isdefined( stub.built ) && stub.built )
                continue;

            if ( stub.buildablezone buildable_has_piece( held ) )
                candidates[candidates.size] = stub;
        }

        if ( candidates.size == 0 )
            continue;

        key = mc_piece_key( held );
        count = 0;

        if ( isdefined( level.mc_have[key] ) )
            count = level.mc_have[key];

        level.mc_have[key] = count + 1;
        self.mc_last_pickup_time = gettime();
        nearest = candidates[0];
        nearest_dist = distancesquared( self.origin, mc_get_stub_origin( nearest ) );

        for ( i = 1; i < candidates.size; i++ )
        {
            d = distancesquared( self.origin, mc_get_stub_origin( candidates[i] ) );

            if ( d < nearest_dist )
            {
                nearest_dist = d;
                nearest = candidates[i];
            }
        }

        names = mc_display_name( candidates[0].buildablezone.buildable_name );

        for ( i = 1; i < candidates.size; i++ )
            names = names + " / " + mc_display_name( candidates[i].buildablezone.buildable_name );

        if ( level.mc_debug )
            println( "[mc_debug] piece " + held.buildablename + "/" + held.modelname + " -> candidates=" + candidates.size + " (available for everyone, no random values)" );

        self mc_show_piece_notify( names, mc_representative_icon( nearest.buildablezone.buildable_name ), self mc_progress_text( nearest.buildablezone ) );

        self player_destroy_piece( held );
    }
}

mc_try_deliver_default()
{
    if ( isdefined( self.mc_last_pickup_time ) && gettime() - self.mc_last_pickup_time < 400 )
        return;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !isdefined( stub.buildablezone.pieces ) )
            continue;

        if ( !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        stub_origin = mc_get_stub_origin( stub );

        if ( !mc_in_range( self.origin, stub_origin, mc_build_radius_sq( zone.buildable_name ) ) )
            continue;

        if ( !self usebuttonpressed() )
            continue;

        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( !can_attempt )
            continue;

        if ( isdefined( stub.mc_original_prompt ) )
        {
            if ( !( stub [[ stub.mc_original_prompt ]]( self ) ) )
                continue;
        }

        success = self mc_do_build_hold( stub, zone );

        if ( success )
        {
            deliverable = self mc_get_deliverable_pieces( zone );
            self mc_deliver_pieces( zone, deliverable );
        }
    }
}

find_bench( bench_name )
{
    return getent( bench_name, "targetname" );
}

mc_swap_buildable_fields( stub1, stub2 )
{
    tbz = stub2.buildablezone;
    stub2.buildablezone = stub1.buildablezone;
    stub2.buildablezone.stub = stub2;
    stub1.buildablezone = tbz;
    stub1.buildablezone.stub = stub1;
    tbs = stub2.buildablestruct;
    stub2.buildablestruct = stub1.buildablestruct;
    stub1.buildablestruct = tbs;
    te = stub2.equipname;
    stub2.equipname = stub1.equipname;
    stub1.equipname = te;
    th = stub2.hint_string;
    stub2.hint_string = stub1.hint_string;
    stub1.hint_string = th;
    ths = stub2.trigger_hintstring;
    stub2.trigger_hintstring = stub1.trigger_hintstring;
    stub1.trigger_hintstring = ths;
    tp = stub2.persistent;
    stub2.persistent = stub1.persistent;
    stub1.persistent = tp;
    tobu = stub2.onbeginuse;
    stub2.onbeginuse = stub1.onbeginuse;
    stub1.onbeginuse = tobu;
    tocu = stub2.oncantuse;
    stub2.oncantuse = stub1.oncantuse;
    stub1.oncantuse = tocu;
    toeu = stub2.onenduse;
    stub2.onenduse = stub1.onenduse;
    stub1.onenduse = toeu;
    tt = stub2.target;
    stub2.target = stub1.target;
    stub1.target = tt;
    ttn = stub2.targetname;
    stub2.targetname = stub1.targetname;
    stub1.targetname = ttn;
    twn = stub2.weaponname;
    stub2.weaponname = stub1.weaponname;
    stub1.weaponname = twn;
    pav = stub2.original_prompt_and_visibility_func;
    stub2.original_prompt_and_visibility_func = stub1.original_prompt_and_visibility_func;
    stub1.original_prompt_and_visibility_func = pav;
    bench1 = undefined;
    bench2 = undefined;
    transfer_pos_as_is = 1;

    if ( isdefined( stub1.model ) && isdefined( stub2.model ) && isdefined( stub1.model.target ) && isdefined( stub2.model.target ) )
    {
        bench1 = find_bench( stub1.model.target );
        bench2 = find_bench( stub2.model.target );

        if ( isdefined( bench1 ) && isdefined( bench2 ) )
        {
            transfer_pos_as_is = 0;
            w2lo1 = bench1 worldtolocalcoords( stub1.model.origin );
            w2la1 = stub1.model.angles - bench1.angles;
            w2lo2 = bench2 worldtolocalcoords( stub2.model.origin );
            w2la2 = stub2.model.angles - bench2.angles;
            stub1.model.origin = bench2 localtoworldcoords( w2lo1 );
            stub1.model.angles = bench2.angles + w2la1;
            stub2.model.origin = bench1 localtoworldcoords( w2lo2 );
            stub2.model.angles = bench1.angles + w2la2;
        }

        tmt = stub2.model.target;
        stub2.model.target = stub1.model.target;
        stub1.model.target = tmt;
    }

    tm = stub2.model;
    stub2.model = stub1.model;
    stub1.model = tm;

    if ( transfer_pos_as_is && isdefined( stub1.model ) && isdefined( stub2.model ) )
    {
        tmo = stub2.model.origin;
        tma = stub2.model.angles;
        stub2.model.origin = stub1.model.origin;
        stub2.model.angles = stub1.model.angles;
        stub1.model.origin = tmo;
        stub1.model.angles = tma;
    }
}

mc_try_deliver_buried()
{
    if ( isdefined( self.mc_last_pickup_time ) && gettime() - self.mc_last_pickup_time < 400 )
        return;

    if ( !self usebuttonpressed() )
        return;

    near_bench_stub = undefined;
    best_dist = MC_BUILD_RADIUS_SQ;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        s_orig = mc_get_stub_origin( stub );
        if ( isdefined( s_orig ) && mc_in_range( self.origin, s_orig, MC_BUILD_RADIUS_SQ ) )
        {
            dist = distance2dsquared( self.origin, s_orig );
            if ( dist < best_dist )
            {
                best_dist = dist;
                near_bench_stub = stub;
            }
        }
    }

    if ( !isdefined( near_bench_stub ) )
        return;

    target_stub = undefined;

    foreach ( stub in level.buildable_stubs )
    {
        if ( !isdefined( stub.buildablezone ) || !mc_is_ours( stub.buildablezone.buildable_name ) )
            continue;

        if ( isdefined( stub.table_built ) && stub.table_built )
            continue;

        if ( isdefined( stub.built ) && stub.built )
            continue;

        zone = stub.buildablezone;
        deliverable = self mc_get_deliverable_pieces( zone );
        can_attempt = false;

        if ( mc_is_gated( zone.buildable_name ) )
            can_attempt = deliverable.size > 0 && deliverable.size == mc_count_remaining( zone );
        else
            can_attempt = deliverable.size > 0;

        if ( can_attempt )
        {
            target_stub = stub;
            break;
        }
    }

    if ( !isdefined( target_stub ) )
        return;

    if ( near_bench_stub != target_stub )
    {
        mc_swap_buildable_fields( near_bench_stub, target_stub );
    }

    near_bench_stub.bound_to_buildable = near_bench_stub;
    active_stub = near_bench_stub;

    target_b_name = active_stub.buildablezone.buildable_name;

    success = self mc_do_build_hold( active_stub, active_stub.buildablezone );

    if ( success )
    {
        deliverable = self mc_get_deliverable_pieces( active_stub.buildablezone );
        self mc_deliver_pieces( active_stub.buildablezone, deliverable );

        active_stub.table_built = true;
        active_stub.built = true;
        active_stub.bound_to_buildable = undefined;
    }
}

custom_pooledbuildable_stub_for_piece( piece )
{
    if ( !isdefined( piece ) )
        return undefined;

    if ( !isdefined( self.stubs ) )
        return undefined;

    foreach ( stub in level.buildable_stubs )
    {
        if ( isdefined( stub.buildablezone ) && stub.buildablezone buildable_has_piece( piece ) )
        {
            if ( isdefined( stub.bound_to_buildable ) && stub.bound_to_buildable == stub )
                return stub;
        }
    }

    foreach ( stub in level.buildable_stubs )
    {
        if ( isdefined( stub.buildablezone ) && stub.buildablezone buildable_has_piece( piece ) )
        {
            if ( !( isdefined( stub.built ) && stub.built ) )
                return stub;
        }
    }

    foreach ( stub in level.buildable_stubs )
    {
        if ( isdefined( stub.buildablezone ) && stub.buildablezone buildable_has_piece( piece ) )
            return stub;
    }

    return undefined;
}

mc_deliver_pieces( zone, pieces )
{
    for ( i = 0; i < pieces.size; i++ )
    {
        piece = pieces[i];

        if ( isdefined( zone.stub.buildablestruct ) && isdefined( zone.stub.buildablestruct.onuseplantobject ) )
        {
            self player_set_buildable_piece( piece, zone.buildable_slot );
            zone.stub [[ zone.stub.buildablestruct.onuseplantobject ]]( self );
        }

        one_piece = [];
        one_piece[0] = piece;
        self player_build( zone, one_piece );

        key = mc_piece_key( piece );

        if ( isdefined( level.mc_have[key] ) )
        {
            level.mc_have[key] = level.mc_have[key] - 1;

            if ( level.mc_have[key] <= 0 )
                level.mc_have[key] = undefined;
        }
    }
}

mc_do_build_hold( stub, zone )
{
    self endon( "disconnect" );
    self endon( "death" );

    build_time = MC_DEFAULT_BUILD_TIME;

    if ( isdefined( stub.usetime ) )
        build_time = stub.usetime;

    self disable_player_move_states( 1 );
    self increment_is_drinking();
    orgweapon = self getcurrentweapon();
    self giveweapon( "zombie_builder_zm" );
    self switchtoweapon( "zombie_builder_zm" );

    self.mc_buildaudio = spawn( "script_origin", self.origin );
    self.mc_buildaudio playloopsound( "zmb_buildable_loop" );

    self.mc_build_active = 1;
    start_time = gettime();
    self thread mc_build_progress_bar( start_time, build_time );
    self thread mc_build_dust_fx();

    success = true;

    while ( gettime() - start_time < build_time )
    {
        if ( !isdefined( self ) || !self usebuttonpressed() )
        {
            success = false;
            break;
        }

        stub_origin = mc_get_stub_origin( stub );

        if ( !mc_in_range( self.origin, stub_origin, mc_build_radius_sq( zone.buildable_name ) ) )
        {
            success = false;
            break;
        }

        wait 0.05;
    }

    self.mc_build_active = 0;

    if ( isdefined( self.mc_buildaudio ) )
    {
        self.mc_buildaudio delete();
        self.mc_buildaudio = undefined;
    }

    self maps\mp\zombies\_zm_weapons::switch_back_primary_weapon( orgweapon );
    self takeweapon( "zombie_builder_zm" );

    if ( isdefined( self.is_drinking ) && self.is_drinking )
        self decrement_is_drinking();

    self enable_player_move_states();

    return success;
}

mc_build_progress_bar( start_time, build_time )
{
    self endon( "disconnect" );
    self endon( "death" );

    usebar = self createprimaryprogressbar();
    usebartext = self createprimaryprogressbartext();
    usebartext settext( &"ZOMBIE_BUILDING" );

    while ( isdefined( self ) && isdefined( self.mc_build_active ) && self.mc_build_active && gettime() - start_time < build_time )
    {
        progress = ( gettime() - start_time ) / build_time;

        if ( progress < 0 )
            progress = 0;

        if ( progress > 1 )
            progress = 1;

        usebar updatebar( progress );
        wait 0.05;
    }

    usebartext destroyelem();
    usebar destroyelem();
}

mc_build_dust_fx()
{
    self endon( "disconnect" );
    self endon( "death" );

    while ( isdefined( self ) && isdefined( self.mc_build_active ) && self.mc_build_active )
    {
        playfx( level._effect["building_dust"], self getplayercamerapos(), self.angles );
        wait 0.5;
    }
}

mc_progress_text( zone )
{
    built = 0;

    for ( i = 0; i < zone.pieces.size; i++ )
    {
        if ( isdefined( zone.pieces[i].built ) && zone.pieces[i].built )
            built++;
    }

    deliverable = self mc_get_deliverable_pieces( zone );
    have = built + deliverable.size;

    return have + "/" + zone.pieces.size;
}