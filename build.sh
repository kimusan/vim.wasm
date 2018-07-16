#!/bin/bash

set -e

if [ ! -d .git ]; then
    echo 'build.sh must be run from repository root' 1>&2
    exit 1
fi

run_configure() {
    echo "build.sh: Running ./configure"
    CPPFLAGS="-DFEAT_GUI_WASM" \
    CPP="gcc -E" \
    emconfigure ./configure \
        --enable-gui=wasm \
        --with-features=tiny \
        --with-x=no \
        --with-packages=no \
        --with-vim-name=vim.bc \
        --with-modified-by=rhysd \
        --with-compiledby=rhysd \
        --disable-darwin \
        --disable-selinux \
        --disable-xsmp \
        --disable-xsmp-interact \
        --disable-luainterp \
        --disable-mzschemeinterp \
        --disable-perlinterp \
        --disable-pythoninterp \
        --disable-python3interp \
        --disable-tclinterp \
        --disable-rubyinterp \
        --disable-cscope \
        --disable-workshop \
        --disable-netbeans \
        --disable-multibyte \
        --disable-hangulinput \
        --disable-xim \
        --disable-fontset \
        --disable-gtk2-check \
        --disable-gnome-check \
        --disable-motif-check \
        --disable-athena-check \
        --disable-nextaw-check \
        --disable-carbon-check \
        --disable-gtktest \
        --disable-largefile \
        --disable-acl \
        --disable-gpm \
        --disable-sysmouse \
        --disable-nls \
        --disable-channel \
        --disable-terminal \

}

run_make() {
    echo "build.sh: Running make"
    local cflags
    if [[ "$RELEASE" == "" ]]; then
        cflags="-O1 -g -DGUI_WASM_DEBUG"
    else
        cflags="-Os"
    fi
    emmake make -j CFLAGS="$cflags"
    echo "build.sh: Copying bitcode to wasm/"
    cp src/vim.bc wasm/
}

run_emcc() {
    echo "build.sh: Building HTML/JS/Wasm with emcc"

    local extraflags
    if [[ "$RELEASE" == "" ]]; then
        # TODO: EMCC_DEBUG=1
        # TODO: STACK_OVERFLOW_CHECK=1
        # TODO: --js-opts 0
        extraflags="-O0 -g -s ASSERTIONS=1 --shell-file template_vim.html -o vim.html"
    else
        extraflags="-Os --shell-file template_vim_release.html -o index.html"
    fi

    cd wasm/

    if [ ! -f tutor ]; then
        cp ../runtime/tutor/tutor .
    fi

    emcc vim.bc \
        --pre-js pre.js \
        --js-library runtime.js \
        -s "EXPORTED_FUNCTIONS=['_main','_gui_wasm_send_key','_gui_wasm_resize_shell']" -s "EXTRA_EXPORTED_RUNTIME_METHODS=['cwrap']" \
        -s EMTERPRETIFY=1 -s EMTERPRETIFY_ASYNC=1 -s 'EMTERPRETIFY_FILE="emterpretify.data"' \
        -s 'EMTERPRETIFY_WHITELIST=["_gui_mch_wait_for_chars", "_flush_buffers", "_vgetorpeek_one", "_vgetorpeek", "_plain_vgetc", "_vgetc", "_safe_vgetc", "_normal_cmd", "_main_loop", "_inchar", "_gui_inchar", "_ui_inchar", "_gui_wait_for_chars", "_gui_wait_for_chars_or_timer", "_vim_main2", "_main", "_gui_wasm_send_key", "_add_to_input_buf", "_simplify_key", "_extract_modifiers", "_edit", "_invoke_edit", "_nv_edit", "_nv_colon", "_n_opencmd", "_nv_open", "_nv_search", "_fsync", "_mf_sync", "_ml_sync_all", "_updatescript", "_before_blocking", "_getcmdline", "_getexline", "_do_cmdline", "_wait_return", "_op_change", "_do_pending_operator", "_get_literal", "_ins_ctrl_v", "_gui_wasm_resize_shell", "_gui_resize_shell", "_out_flush", "_gui_get_base_width", "_gui_get_base_height", "_gui_position_components", "_gui_reset_scroll_region", "_shell_resized", "_set_shellsize", "_ui_get_shellsize", "_gui_get_shellsize", "_min_rows", "_check_shellsize", "_frame_minheight", "_tabline_height", "_limit_screen_size", "_findoption", "_set_number_default", "_strcmp", "_screenclear", "_check_for_delay", "_screenalloc", "_win_new_shellsize", "_ui_new_shellsize", "_gui_new_shellsize", "_shell_new_rows", "_frame_new_height", "_win_new_height", "_validate_cursor", "_check_cursor_moved", "_scroll_to_fraction", "_plines_win_col", "_ml_get_buf", "_win_col_off", "_plines_win", "_plines_win_nofold", "_curs_columns", "_update_topline", "_screen_valid", "_getvcol", "_curwin_col_off", "_win_col_off2", "_curwin_col_off2", "_win_comp_scroll", "_redraw_win_later", "_invalidate_botline_win", "_frame_check_height", "_win_comp_pos", "_frame_comp_pos", "_compute_cmdrow", "_shell_new_columns", "_frame_new_width", "_win_new_width", "_changed_line_abv_curs_win", "_ml_get", "_redrawing", "_curs_rows", "_redraw_for_cursorline", "_frame_check_width", "_comp_col", "_win_free_lsize", "_vim_free", "_free", "_lalloc", "_malloc", "_win_alloc_lines", "_alloc_clear", "_free_screenlines", "_gui_redraw_block", "_check_col", "_check_row", "_gui_outstr_nowrap", "_syn_gui_attr2entry", "_gui_mch_set_font", "_gui_mch_set_fg_color", "_gui_mch_set_bg_color", "_gui_mch_set_sp_color", "_int_to_hex_char", "_set_color_as_code", "_clip_may_clear_selection", "_gui_mch_draw_string", "_draw_rect", "_apply_autocmds_group", "_apply_autocmds", "_screenclear2", "_screen_stop_highlight", "_clip_scroll_selection", "_lineclear", "_can_clear", "_out_str", "_out_str_nf", "_out_char_nf", "_win_rest_invalid", "_screen_start", "_changed_line_abv_curs", "_invalidate_botline", "_update_screen", "_draw_tabline", "_cursor_off", "_clip_isautosel_star", "_vim_strchr", "_clip_update_selection", "_clip_isautosel_plus", "_gui_undraw_cursor", "_win_update", "_win_line", "_vim_isprintc", "_screen_line", "_draw_vsep_win"]' \
        --preload-file usr --preload-file tutor \
        $extraflags \

}

run_release() {
    echo "build.sh: Cleaning built files"
    make distclean
    rm -rf wasm
    git checkout wasm/
    export RELEASE=true
    echo "build.sh: Start release build"
    bash build.sh
    echo "build.sh: Release build done"
}

run_deploy() {
    echo "build.sh: Deploying gh-pages"
    local hash
    hash="$(git rev-parse HEAD)"
    cp wasm/style.css _style.css
    git checkout gh-pages
    mv _style.css style.css
    cp wasm/index.* .
    rm index.js.orig.js
    cp wasm/emterpretify.data .
    git add index.* emterpretify.data
    git commit -m "Deploy from ${hash}"
    echo "build.sh: Commit created. Please check diff with 'git show' and deploy it with 'git push'"
}

if [[ "$#" != "0" ]]; then
    for task in "$@"; do
        "run_${task}"
    done
else
    run_configure
    run_make
    run_emcc
fi

echo "Done."
