# -*- coding: utf-8 -*-
def bm_string
  Benchmark.benchmark("", 30, "%r\n") do |x|
    string_chomp(x)
    string_concat(x)
    string_dup(x)
    string_gsub(x)
    string_equal(x)
    string_include(x)
    string_index(x)
    string_length(x)
    string_match(x)
    string_new(x)
    string_reverse(x)
    string_slice(x)
    string_split(x)
    string_to_f(x)
    string_to_i(x)
    string_to_sym(x)
  end
end

$short_sentence_ascii =<<EOS
IN THE YEAR 1878 I took my degree of Doctor of Medicine of the University of
London, and proceeded to Netley to go through the course prescribed for
surgeons in the Army. Having completed my studies there, I was duly attached
to the Fifth Northumberland Fusiliers as assistant surgeon. The regiment was
stationed in India at the time, and before I could join it, the second Afghan
war had broken out. On landing at Bombay, I learned that my corps had advanced
through the passes, and was already deep in the enemy's country. I followed,
however, with many other officers who were in the same situation as myself, and
succeeded in reaching Candahar in safety, where I found my regiment, and at
once entered upon my new duties. 
EOS

$short_sentence_utf8 =<<EOS
1878年に私はロンドン大学の医学博士号を取った。そしてネットレイに進み、陸軍
で軍医となるための規定研修を受けた。そこでの研修を終え私はただちに第五ノー
サンバーランド・フィージリア連隊に軍医補として配属された。連隊はその時イン
ドに駐留しており、私の配属前に第二アフガン戦争が勃発していた。ボンベイに上
陸して私の軍隊はいくつも峠を越えて進軍していた事が分かった。そしてすでに敵
地深くにいることが。しかし、私は後を追った。私と同じ状況にある他の沢山の将
校と共に。そして、無事にカンダハールに到着することに成功した。そこで私は自
分の連隊を見つけそしてすぐに私は自分の新しい任務についた。
EOS