report zcelebi_p001.

parameters: p_key   type string obligatory lower case,
            p_input type string default 'Merhaba! Bana 1 cümlelik bir selam yaz.'.

constants c_url type string value 'https://api.openai.com/v1/responses'.

data: lo_http   type ref to if_http_client,
      lv_body   type string,
      lv_json   type string,
      lv_code   type i,
      lv_reason type string.

start-of-selection.

  " --- HTTP client
  try.
      cl_http_client=>create_by_url(
        exporting url    = c_url
        importing client = lo_http ).
    catch cx_root into data(lx_url).
      message lx_url->get_text( ) type 'E'.
  endtry.

  " --- Headers
  lo_http->request->set_method( if_http_request=>co_request_method_post ).
  lo_http->request->set_header_field( name = 'Content-Type'  value = 'application/json' ).
  lo_http->request->set_header_field( name = 'Accept'        value = 'application/json' ).
  lo_http->request->set_header_field( name = 'Authorization' value = |Bearer { p_key }| ).


  lv_body = `{"model":"gpt-5-mini","input":"{ ` && p_input && ` }"}`.




  " JSON'un debug için çıktısını gör
  write: / 'BODY JSON:', lv_body.

  lo_http->request->set_cdata( lv_body ).

  " --- Gönder & al
  try.
      lo_http->send( ).
      lo_http->receive( ).
    catch cx_root into data(lx_http).
      message lx_http->get_text( ) type 'E'.
  endtry.

  lo_http->response->get_status( importing code = lv_code reason = lv_reason ).
  lv_json = lo_http->response->get_cdata( ).

  data: lv_response type string, " JSON string'in tamamı burada
        lv_text     type string.

  " Tipler
  types: begin of ty_content,
           type type string,
           text type string,
         end of ty_content.
  types tt_content type standard table of ty_content with empty key.

  types: begin of ty_output,
           id      type string,
           type    type string,
           status  type string,
           content type tt_content,
           role    type string,
         end of ty_output.
  types tt_output type standard table of ty_output with empty key.

  types: begin of ty_resp,
           id     type string,
           object type string,
           output type tt_output,
         end of ty_resp.

  data ls_resp type ty_resp.

  lv_response  = lv_json.

  " JSON -> ABAP
  /ui2/cl_json=>deserialize(
    exporting
      json        = lv_response
      pretty_name = /ui2/cl_json=>pretty_mode-none
    changing
      data        = ls_resp ).

  " İçeriği al
  loop at ls_resp-output into data(ls_out).
    loop at ls_out-content into data(ls_cont) where type = 'output_text'.
      if ls_cont-text is not initial.
        lv_text = ls_cont-text.
        exit. " ilk bulduğunu al
      endif.
    endloop.
  endloop.

  write: / 'Model cevabı:', lv_text.




*  write: / 'HTTP Code:', lv_code, lv_reason.
*  write: / 'Response:', lv_json.

  lo_http->close( ).