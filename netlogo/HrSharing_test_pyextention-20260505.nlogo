extensions [ py csv ]
breed [companies company]

globals [
  γ
  sharing-list ;; シェア当番リスト （リスト）
  sharing-active?   ;; true / false
  degree-of-variability
  ;  scenario-print
  ;  variability-print
  day
  RL-who   ;; 学習対象 company の who（整数）
  RL-who-list
  py-result
  debug-one-tick?
  rl-action-this-tick
  setup-count
  py-initialized?
  workload-threshold
  experiment-id
  last-reward
]

companies-own [
  αt
  βt
  βt-1
  δt
  θt
  θt-ds
  rl-θt ;; Pythonから書き込む人材交渉数（整数）
  Total-θt-plus
  Total-θt-minus
  status
  n ;;CSV
  point-of-Sharing ;;CSV
  annual-α ;;CSV
  result ;;Evaluation
  result2 ;;Evaluation
  Total-β ;;Evaluation
  Total-θ ;;Evaluation
  Total-duty ;;Evaluation
  Total-workload ;;Evaluation
  potential-workload
  duty
  weekly-αlist
  rl-action ;; Pythonから書き込む行動値（整数）
  supply-remaining ;; Pythonから受け取る行動値のtick内残量（整数）
  ;obs ;; observation (文字列)
]



to aaaaa [bbbbb]
  print bbbbb
end

to-report returnfunc [a b c]
  report a * b * c
end


to-report encode-status [s]
  if s = "normal" [ report [1 0 0] ]
  if s = "busy"   [ report [0 1 0] ]
  if s = "idle"   [ report [0 0 1] ]
end


to-report get_obs [c]
  let s encode-status [status] of c
  ;report sentenc(list
  report (list
    [αt] of c
    [βt] of c
    [βt-1] of c
    [δt] of c
    [point-of-Sharing] of c
    [annual-α] of c
    [n] of c
    [rl-θt] of c
    item 0 s
    item 1 s
    item 2 s
    ;encode-status [status] of c ;[status] of c
    )
    ;encode-status [status] of c
end

to setup
  clear-all
  reset-ticks
  set γ 8
  set day 1
  set-default-shape companies "company"
  read-companies-from-csv
  layout-circle sort companies (world-width / 2.3 - 1)
  random-seed my-seed
  setting-sinario
  repeat 12 [monthly-func]

  ;set RL-who 1  ;; 学習対象 company の who を指定（例: 1）
  ;set RL-who-list map [ read-from-string ? ] (sentence RL-who-list-str)
  ;set RL-who-list map [ x -> read-from-string x ] (sentence RL-who-list-str)

  ;; 空文字なら空リスト
  ifelse RL-who-list-str = "" [ set RL-who-list []][
    set RL-who-list read-from-string (word "[" RL-who-list-str "]")]
  ;単体でテストする場合は、以下のように直接リストを指定してもOK
  ;set RL-who-list read-from-string (word "[" RL-who-list-str "]")


  ;if not py-initialized? [

  ;py:setup "/home/b17z6ms/src/venv-pynetlogo/bin/python"
  py:setup "/home/m-saito/rl_env/bin/python"
  py:run "import sys"
  py:run "sys.path.append('/home/m-saito/research_project')"

  ;py:run "print('python ready')"
  ;py:run "from pyextention_policy import policy_step"
  ;py:run "import rl_agent"
  py:run "from importlib import reload"
  py:run "import python_rl.rl_agent as rl_agent"
  py:run "reload(rl_agent)"
  py:run "rl_agent.init_agent()"


  ;py:run "from python_rl import rl_agent"
  ;print "[NL] setup finished"
  ;py:run "rl_agent.init_agent()"

  ;  set py-initialized? true
  ;]
  set debug-one-tick? true   ;; デバッグモード：1ティックで停止
end




;; setupの子供関数
to read-companies-from-csv
  file-close-all ;; close all open files
  if not file-exists? "input.csv" [
    user-message "No file 'input.csv' exists! Try pressing WRITE-COMPANIES-TO-CSV."
    stop
  ]
  file-open "input.csv"
  while [ not file-at-end? ] [
    ;; here the CSV extension grabs a single line and puts the read data in a list
    let data csv:from-row file-read-line
    ;; now we can use that list to create a turtle with the saved properties
    create-companies 1 [
      set color brown
      set size 3.5
      set n item 0 data
      set point-of-Sharing item 1 data
      set annual-α item 2 data
      set weekly-αlist []
      set βt 0
      set βt-1 0
      set θt-ds 0
      set rl-θt 0
      set result 0
      set result2 0
      set Total-β 0
      set status "normal"
      set Total-θ 0
      set Total-duty 0
      set Total-workload 0
      set potential-workload 0
      set Total-θt-plus 0
      set Total-θt-minus 0
      set label who
    ]
  ]
  file-close ;; make sure to close the file
end

to setting-sinario
  if (variability = 1)[
    set degree-of-variability 1
    ;    set variability-print "Variability rate 1.00, employees can do all the work by themselves. The total working hours do not fluctuate at all."
  ]
  if (variability = 1.25)[
    set degree-of-variability 1.077
    ;    set variability-print "Variability rate 1.25, the total working hours fluctuate depending on the day."
  ]
  if (variability = 1.50)[
    set degree-of-variability 1.144
    ;    set variability-print "Variability rate 1.50, the total working hours fluctuate depending on the day."
  ]
  if (variability = 1.75)[
    set degree-of-variability 1.205
    ;    set variability-print "Variability rate 1.75, the total working hours fluctuate depending on the day."
  ]
  if (variability = 2.00)[
    set degree-of-variability 1.259
    ;    set variability-print "Variability rate 2.00, the total working hours fluctuate depending on the day."
  ]
  ;  if (scenario = 0)[set scenario-print "Scenario 0 is 'No sharing (default)'. Employees complete total required working hours by themselves. "]
  ;  if (scenario = 1)[set scenario-print "Scenario 1 is 'Negotiate with one randomly selected company'. "]
  ;  if (scenario = 2)[set scenario-print "Scenario 2 is 'Negotiate with one randomly selected company × S times'. "]
  ;  if (scenario = 3)[set scenario-print "Scenario 3 is 'Negotiate with selected company with the maximum value of |βt|'. "]
  ;  if (scenario = 4)[set scenario-print "Scenario 4 is 'Negotiate with selected company with the maximum value of |βt| × S times'. "]
end

to monthly-func
  ask companies [
    let monthly-α ( annual-α / 12 + random ((degree-of-variability - 1) * annual-α / 6) - (degree-of-variability - 1) * annual-α / 12)
    repeat 4 [weekly-func monthly-α]
  ]
end

to weekly-func [monthly-α]
  let weekly-α ( monthly-α / 4 + random ((degree-of-variability - 1) * monthly-α / 2) - (degree-of-variability - 1) * monthly-α / 4)
  set weekly-αlist fput round weekly-α weekly-αlist
end



to-report tick-start
  if not any? companies [
    ;print "[NL] no companies"
    report nobody
  ]

  report 0   ;; 今はダミー action
end
to apply-action-self [action]
  ;; turtle context
  ;set workload workload + action
end
to-report calc-reward [c]
  report [result] of c
end

to apply-action [c action]
  ask c [
    set rl-θt rl-θt + action
    set result rl-θt
  ]
end


to go
  ;ask companies [print (word "who=" who " αt=" αt " βt=" βt " status=" status)]



  ;; ---- 日更新 ----
  if day > 5 [set day 1
              ask companies [set weekly-αlist but-first weekly-αlist]]

    ;; ---- 内部状態更新 ----
  ask companies [
    set αt ( first weekly-αlist / 5 + random ((degree-of-variability - 1) * first weekly-αlist / 2.5) - (degree-of-variability - 1) * first weekly-αlist / 5)
    ifelse (βt > 0)[set βt-1 βt][set βt-1 0] ;Carrying forward the previous value
    set δt 0
    set θt 0
    set duty 0
    juge-func
  ]

;; =========================================
;; RL INTERACTION
;; =========================================
if not empty? RL-who-list [

  let chosen-who read-from-string one-of RL-who-list
  let candidates companies with [ who = chosen-who ]

  if any? candidates [

    let c one-of candidates

    ;;show (word "[RL] Chosen company: " [who] of c)
    ;; ① 状態
    let obs get_obs c

    py:set "obs" obs
    py:set "who" [who] of c

    ;; ② 行動
    let action py:runresult "rl_agent.policy_step(obs)"

    ;; ③ 行動適用
    show (word "before βt=" [βt] of c)
    apply-action c action
    ask c [　set θt rl-θt　]

    ;; ===== 環境更新 =====
    scenario-func-fix c
    ;;show (word "after βt=" [βt] of c)
    ;;show (word "reward=" last-reward)

    ;; ===== 報酬 r_t =====
    set last-reward calc-reward c
    show (word "[reward]=" last-reward)

    ;; ===== 次状態 s_{t+1} =====
    let next_obs get_obs c

    ;; ===== 終了判定 =====
    let done (ticks + 1 >= 240)

    ;;print (word  "tick=" ticks)
    if ticks mod 50 = 0 [ show ticks]

    ;; ===== Pythonへ送信 =====
    py:set "obs" obs
    py:set "action" action
    py:set "reward" last-reward
    py:set "next_obs" next_obs
    py:set "done" done

    py:run "rl_agent.store_transition(obs, action, reward, next_obs, done)"
    ;py:run "rl_agent.save_model('../models/model.pt')"
    ;py:run "rl_agent.save_model()"


    file-open "rl_debug.log"

    file-print (word
      ticks ","
      [who] of c ","
      obs ","
      action ","
      last-reward
    )

    file-close


  ]
]

;; ===== 統計更新 =====
result-func

;; ---- 日更新 ----
set day (day + 1)

;; ---- 時間更新 ----

if ticks mod 10 = 0 [ show ticks ]
tick

;; ---- 終了判定 ----
if ticks >= 240 [
    print "NETLOGO SAVE START"
    ;py:run "rl_agent.save_model('/home/m-saito/research_project/models/model.pt')"
    py:run (word "rl_agent.save_model('/home/m-saito/research_project/models/model_" behaviorspace-run-number ".pt')")
    print "NETLOGO SAVE END"
    stop
  ]


end


;; goの子供関数
to juge-func
  set βt (αt + βt-1 - (n * γ) - (n * δt) - (θt * γ))
  ;print (word "[NL] ENTER juge-func, ticks=" ticks ", 企業" who "のβtは" βt)
  if βt >= γ [set status "busy"  set color red ]
  if βt <= ( - γ) [ set status "idle" set color blue]
  if (abs βt < γ) [ set status "normal" set color brown ]
end

to scenario-func-fix [c]
  ;print (word "[NL] ENTER scenario-func-fix, ticks=" ticks)
  ;ask companies [
  ;print (word "who=" who " αt=" αt " βt=" βt " status=" status)
  ;]
  ;; シナリオごとに交渉する会社を決定し、交渉を行う
  with-local-randomness [
    if scenario != 0 [ sharing-list-func ]
    ] ;; シェア当番リスト作成
  if not is-list? sharing-list [
    user-message (word "ERROR: sharing-list is not a list: " sharing-list)
    stop
  ]
  while [ not empty? sharing-list ] [
    let ttt first sharing-list ;;Sharing duty is ttt 当番
    set sharing-list but-first sharing-list ;;リストから先頭（当番）を削除
    let deal-made? false

    ;;If the on-duty company is busy and there is a idle period
    ;;もしも当番会社tttが繁忙期でシェアPが0以上、かつ他に閑散期の会社があるならば
    ifelse (
      ([status = "busy" and point-of-Sharing > 0] of company ttt)
      and
      (any? companies with [status = "idle"])
      ) [
      ;;シナリオごとに交渉する会社qqqを決定
      let qqq first [who] of companies with [status = "idle"]
      if (scenario = 2)[set qqq first [who] of companies with [status = "idle"] with-min [βt]]
      ask company ttt [watch-me create-link-to company qqq ]
      ;;tttが1の場合、企業1のθt-dsを上限制御（supply-remaining）以下にする。
      ifelse (ttt = c) [

        if ([supply-remaining] of company c > 0) [

          ;; ① 状態取得
          let obs get_obs c

          ;; ② Pythonに行動問い合わせ
          let action py:runresult (word "policy_step(" obs ")")

          ;; ③ 制約をNetLogo側で適用
          ask company c [
            set θt-ds min (list
              action
              point-of-Sharing
              (abs int [βt / γ] of company qqq)
              supply-remaining
            )
            set supply-remaining supply-remaining - θt-ds
            ;print (word "[NL] ttt =" who " αt=" αt " βt=" βt " status=" status)
            ;print (word "[NL] θt=" θt " θt-ds=" θt-ds)
          ]

          set deal-made? true
        ]


      ][
        ;;それ以外は通常の交渉処理
        ;; Number of people sharing is the minimum of the three numbers
        set deal-made? true
        ask company ttt [
          set θt-ds min (list
              (abs int [βt / γ] of company ttt)
              ([point-of-Sharing] of company ttt)
              (abs int [βt / γ] of company qqq)
            )
          ;print (word "[NL] who=" who " θt-ds="θt-ds " αt=" αt " βt=" βt " status=" status)
          ]
        ]
        negolink-func_b-to-i ttt qqq
        ask company qqq [
          set θt-ds (- [θt-ds] of company ttt)
          ;print (word "[NL] who=" who " θt-ds="θt-ds " αt=" αt " βt=" βt " status=" status)
          ]
        ;;Calculation of sharing points and number of people sharing each other
        negocalc-func ttt qqq
        ask companies [
          ;print (word "[NL] who=" who " αt=" αt " βt=" βt " status=" status)
          juge-func
          ]
      ][ ;;If the on-duty company is idle and there is a busy period
      if ([status = "idle"] of company ttt) and (any? companies with [status = "busy" and point-of-Sharing > 0]) [
      ;;シナリオごとに交渉する会社qqqを決定
        let qqq first [who] of companies with [status = "busy" and point-of-Sharing > 0]
        if (scenario = 2)[set qqq first [who] of companies with [status = "busy" and point-of-Sharing > 0] with-max [βt]]
        ask company ttt[watch-me create-link-to company qqq ]
        ;;qqq1の場合、企業1のθt-dsを上限制御（supply-remaining）以下にする。
        ifelse (qqq = c) [
            if ([supply-remaining] of company c > 0) [

            ;; ① 状態取得
            let obs get_obs c

            ;; ② Pythonに行動問い合わせ
            let action py:runresult (word "policy_step(" obs ")")

            ;; ③ 制約をNetLogo側で適用
            ask company c [
              set θt-ds min (list
                action
                point-of-Sharing
                (abs int [βt / γ] of company ttt)
                supply-remaining
              )
              set supply-remaining supply-remaining - θt-ds
              ;print (word "[NL] qqq=" who " αt=" αt " βt=" βt " status=" status)
              ;print (word "θt=" θt " θt-ds=" θt-ds)
            ]

            set deal-made? true
          ]


        ][
          ;;それ以外は通常の交渉処理
          ;;Number of people sharing is the minimum of the three numbers
          set deal-made? true
          ask company qqq[
            set θt-ds min (list
             (abs int [βt / γ] of company qqq)
             ([point-of-Sharing] of company qqq)
             (abs int [βt / γ] of company ttt)
            )
          ]
        ]
        negolink-func_i-to-b ttt qqq
        ask company ttt[set θt-ds (- [θt-ds] of company qqq)]
        ;;Calculation of sharing points and number of people sharing each other
        negocalc-func ttt qqq
        ask companies [
          ;print (word "who=" who " αt=" αt " βt=" βt " status=" status)
          juge-func
          ]
      ]
    ]
    ask links [die] rp
    if not any? companies with [status = "busy" and point-of-Sharing > 0][print "stop:scenario-func-fix, busy companies have no point" set sharing-list []]
    print sharing-list
  ]
  ask links [die] rp
end



to result-func
  ask companies [
    set Total-β (Total-β + abs(βt))
    set Total-θ (Total-θ + abs(θt))
    set result (Total-β / n)
    set Total-duty (Total-duty + duty)
    set potential-workload ((n * γ) + (n * δt) + (θt * γ))  ;; 本日こなせる仕事量
    ifelse ((αt + βt-1) > potential-workload)[;; こなした仕事量合計算出
      set Total-workload (Total-workload + potential-workload )
    ][set Total-workload (Total-workload + αt + βt-1)]
    set result2 (Total-workload / n)
    ifelse θt > 0[
      set Total-θt-plus (Total-θt-plus + θt)
    ][ set Total-θt-minus (Total-θt-minus + θt) ]
  ]
  ;  print (word ticks "," who ", Total-duty:" Total-duty)
end

;; goの孫関数
to sharing-list-func
  ;print (word "[NL] ENTER sharing-list-func, ticks=" ticks)
  ;set sharing-list ( n-values count companies[i -> i] )
  set sharing-list sort [who] of companies with [status != "normal"]
  ;print (word "初期sharing-list:" sharing-list)
  if not is-list? sharing-list [
    user-message (word "sharing-list broken at init: " sharing-list)
    set sharing-list []
  ]
  ;; Normal status companies are removed from the list
  let nnn ( [who] of companies with [status = "normal"] )
  repeat (length nnn) [set sharing-list remove first nnn sharing-list set nnn but-first nnn]
  set sharing-list shuffle sharing-list

  ;;確認出力
  type "sharing-list:" print sharing-list
end

to overtime-func
  if (max-daily-overtime-minute / 60 * n <= βt)[set δt (max-daily-overtime-minute / 60)]
  if (max-daily-overtime-minute / 60 * n > βt)[set δt (βt / n)]
end


;;;; scenario-funcの孫関数
to negolink-func_b-to-i [ttt qqq]
  ask link ttt qqq [
    set label [θt-ds] of company ttt
    set color red
    set thickness 1
  ]
end

to negolink-func_i-to-b [ttt qqq]
  ask link ttt qqq [
    set label [θt-ds] of company ttt
    set color blue
    set thickness 1
  ]
end

to negocalc-func [ttt qqq]
  ;;Calculation of sharing points and number of people sharing each other
  ask company ttt[set point-of-Sharing (point-of-Sharing - θt-ds)]
  ask company qqq[set point-of-Sharing (point-of-Sharing - θt-ds)]
  ask company ttt[set θt (θt + θt-ds) set θt-ds 0
  ;print (word "tick=" ticks " company=" who)
  ;print (word "company=" who) type"ネゴ時ticksは、" print ticks
  ]
  ask company qqq[set θt (θt + θt-ds) set θt-ds 0
  ;print (word "tick=" ticks " company=" who)
  ;print (word "company=" who) type"ネゴ時ticksは、" print ticks
  ]

  ;;確認出力
  type"ネゴ時ticksは、" print ticks
  ask company ttt [
    print (word
      length sharing-list
      " 列-当番企業名 "
      who
      " ,θt: "
      θt
      " ,θt-ds: "
      θt-ds
    )
  ]

  ;ask company qqq [
  ;  print (word
  ;    length sharing-list
  ;    " 列-相手企業名 "
  ;    who
  ;    " ,θt: "
  ;    θt
  ;    " ,θt-ds: "
  ;    θt-ds
  ;  )
  ;]






  ;ask company ttt [type length sharing-list type "列-当番企業名" type who type ",θt:" print θt ",θt-ds:" type θt-ds type]
  ;ask company qqq [type length sharing-list type "列-相手企業名" type who type ",θt:" print θt ",θt-ds:" type θt-ds type]
end


to distribution-func
  ;; dividend  分配金（スライダーで設定）
  ask companies [
    if not any? companies with [point-of-Sharing = 0] [stop]
    ;;n-poor数の1/2の金持ち企業が集まって、貧乏企業一社あたりdividend分ずつのポイントを分配する。
    let poor companies with [point-of-Sharing = 0]
    let n-poor count poor
    let n-millionaire ceiling(n-poor / distributionScenario)
    let millionaire max-n-of n-millionaire companies [point-of-Sharing]
    ifelse not any? millionaire with [point-of-Sharing < dividend * distributionScenario][
      ask millionaire [
        set duty dividend * distributionScenario
        set point-of-Sharing point-of-Sharing - duty
      ]
      ask poor [
        set point-of-Sharing point-of-Sharing + dividend
      ]

      let ccc first [who] of millionaire with-min [point-of-Sharing]
      ask company ccc[
        let cashBack sum [duty] of millionaire - sum [dividend] of poor
        set point-of-Sharing point-of-Sharing + cashBack
      ]
    ][ ;;シェアPにマイナスをださない処理
      let dividend2 int (min [point-of-Sharing] of millionaire / distributionScenario)
      ask millionaire [
        set duty dividend2 * distributionScenario
        set point-of-Sharing point-of-Sharing - duty
      ]
      ask poor [
        set point-of-Sharing point-of-Sharing + dividend2
      ]
      let ccc first [who] of millionaire with-min [point-of-Sharing]
      ask company ccc[
        let cashBack sum [duty] of millionaire - sum [dividend2] of poor
        set point-of-Sharing point-of-Sharing + cashBack
      ]
    ]
    ;    print (word ticks ", sum-duty:" sum [duty] of millionaire ", dividend:" [dividend] of one-of poor ", millionaire:" [who]of millionaire ", poor:" [who]of poor)
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
252
10
689
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
20
225
75
270
NIL
setup\n
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
15
400
100
460
my-seed
0.0
1
0
Number

CHOOSER
20
55
125
100
variability
variability
1 1.25 1.5 1.75 2
2

SLIDER
15
360
230
393
number-of-negotiations
number-of-negotiations
1
10
3.0
1
1
NIL
HORIZONTAL

BUTTON
80
225
180
271
go for 240 days
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
255
665
700
840
[βt] = ((αt) + (max (0,β(t-1))) - ((n * γ) + (N * δt) + (θt * γ))\n[result]= (|βt| / n) * 240days    Total value of “busyness and idleness per person per year”\n[αt] = total working hours per day (fluctuates daily)\n[n]= number of employees (fixed)\n[δt]= overtime working hours per person (maximum 30 minutes · calculated after share negotiation · initial value 0)\n[θt]= number of shared employees\n[γ] = standard working hours (8 hours per person fixed)\n
12
33.0
1

CHOOSER
135
55
227
100
scenario
scenario
0 1 2
2

MONITOR
10
465
230
510
sum [result] of companies
int sum [result] of companies\n;[Total-results] of company 0
17
1
11

PLOT
717
10
1172
314
[result] of companies
days
NIL
0.0
240.0
0.0
10.0
true
true
"" ""
PENS
"0" 1.0 0 -16777216 true "" "plotxy ticks [result] of company 0"
"1" 1.0 0 -7500403 true "" "plotxy ticks [result] of company 1"
"2" 1.0 0 -2674135 true "" "plotxy ticks [result] of company 2"
"3" 1.0 0 -955883 true "" "plotxy ticks [result] of company 3"
"4" 1.0 0 -6459832 true "" "plotxy ticks [result] of company 4"
"5" 1.0 0 -1184463 true "" "plotxy ticks [result] of company 5"
"6" 1.0 0 -10899396 true "" "plotxy ticks [result] of company 6"
"7" 1.0 0 -13840069 true "" "plotxy ticks [result] of company 7"
"8" 1.0 0 -14835848 true "" "plotxy ticks [result] of company 8"
"9" 1.0 0 -11221820 true "" "plotxy ticks [result] of company 9"
"10" 1.0 0 -13791810 true "" "plotxy ticks [result] of company 10"
"11" 1.0 0 -13345367 true "" "plotxy ticks [result] of company 11"
"12" 1.0 0 -8630108 true "" "plotxy ticks [result] of company 12"
"13" 1.0 0 -5825686 true "" "plotxy ticks [result] of company 13"
"14" 1.0 0 -2064490 true "" "plotxy ticks [result] of company 14"
"15" 1.0 0 -16777216 true "" "plotxy ticks [result] of company 15"
"16" 1.0 0 -11053225 true "" "plotxy ticks [result] of company 16"

SLIDER
16
321
231
354
max-daily-overtime-minute
max-daily-overtime-minute
0
120
30.0
15
1
NIL
HORIZONTAL

PLOT
721
622
1176
928
[θt] of companies per day
days
persons
0.0
240.0
-10.0
10.0
true
true
"" ""
PENS
"0" 1.0 0 -16777216 true "" "plotxy ticks [θt] of company 0"
"1" 1.0 0 -7500403 true "" "plotxy ticks [θt] of company 1"
"2" 1.0 0 -2674135 true "" "plotxy ticks [θt] of company 2"
"3" 1.0 0 -955883 true "" "plotxy ticks [θt] of company 3"
"4" 1.0 0 -6459832 true "" "plotxy ticks [θt] of company 4"
"5" 1.0 0 -1184463 true "" "plotxy ticks [θt] of company 5"
"6" 1.0 0 -10899396 true "" "plotxy ticks [θt] of company 6"
"7" 1.0 0 -13840069 true "" "plotxy ticks [θt] of company 7"
"8" 1.0 0 -14835848 true "" "plotxy ticks [θt] of company 8"
"9" 1.0 0 -11221820 true "" "plotxy ticks [θt] of company 9"
"10" 1.0 0 -13791810 true "" "plotxy ticks [θt] of company 10"
"11" 1.0 0 -13345367 true "" "plotxy ticks [θt] of company 11"
"12" 1.0 0 -8630108 true "" "plotxy ticks [θt] of company 12"
"13" 1.0 0 -5825686 true "" "plotxy ticks [θt] of company 13"
"14" 1.0 0 -2064490 true "" "plotxy ticks [θt] of company 14"
"15" 1.0 0 -16777216 true "" "plotxy ticks [θt] of company 15"
"16" 1.0 0 -11053225 true "" "plotxy ticks [θt] of company 16"

PLOT
719
317
1174
619
[point-of-Sharing] of companies
days
points
0.0
240.0
0.0
10.0
true
true
"" ""
PENS
"0" 1.0 0 -16777216 true "" "plotxy ticks [point-of-Sharing] of company 0"
"1" 1.0 0 -7500403 true "" "plotxy ticks [point-of-Sharing] of company 1"
"2" 1.0 0 -2674135 true "" "plotxy ticks [point-of-Sharing] of company 2"
"3" 1.0 0 -955883 true "" "plotxy ticks [point-of-Sharing] of company 3"
"4" 1.0 0 -6459832 true "" "plotxy ticks [point-of-Sharing] of company 4"
"5" 1.0 0 -1184463 true "" "plotxy ticks [point-of-Sharing] of company 5"
"6" 1.0 0 -10899396 true "" "plotxy ticks [point-of-Sharing] of company 6"
"7" 1.0 0 -13840069 true "" "plotxy ticks [point-of-Sharing] of company 7"
"8" 1.0 0 -14835848 true "" "plotxy ticks [point-of-Sharing] of company 8"
"9" 1.0 0 -11221820 true "" "plotxy ticks [point-of-Sharing] of company 9"
"10" 1.0 0 -13791810 true "" "plotxy ticks [point-of-Sharing] of company 10"
"11" 1.0 0 -13345367 true "" "plotxy ticks [point-of-Sharing] of company 11"
"12" 1.0 0 -8630108 true "" "plotxy ticks [point-of-Sharing] of company 12"
"13" 1.0 0 -5825686 true "" "plotxy ticks [point-of-Sharing] of company 13"
"14" 1.0 0 -2064490 true "" "plotxy ticks [point-of-Sharing] of company 14"
"15" 1.0 0 -16777216 true "" "plotxy ticks [point-of-Sharing] of company 15"
"16" 1.0 0 -11053225 true "" "plotxy ticks [point-of-Sharing] of company 16"

MONITOR
10
555
230
600
NIL
sum [point-of-Sharing] of companies
17
1
11

BUTTON
530
490
692
535
point-of-Sharing
set label  point-of-Sharing\nset label-color yellow
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
585
550
687
596
βt
set label  int βt\nset label-color 97
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
415
550
575
600
Total Sharing employees
set label Total-θ\nset label-color 117
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
255
490
355
535
ID
set label who\nset label-color white
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

MONITOR
10
600
230
645
NIL
sum [Total-θ] of companies
17
1
11

PLOT
1185
320
1580
470
count companies with [point-of-Sharing > 320, 500]
days
NIL
0.0
240.0
0.0
3.0
false
true
"" ""
PENS
"over320" 1.0 0 -16777216 true "" "plot count companies with [point-of-Sharing > 320]"
"over500" 1.0 0 -5298144 true "" "plot count companies with [point-of-Sharing > 470]"

PLOT
1188
630
1603
780
count companies with [θt = 0],  [status = "normal"]
days
NIL
0.0
240.0
0.0
17.0
true
true
"" ""
PENS
"no-sharing" 1.0 0 -16777216 true "" "plotxy ticks count companies with [θt = 0]"
"normal" 1.0 0 -6459832 true "" "plotxy ticks count companies with [status = \"normal\"]"

BUTTON
370
490
515
535
annual working hour
set label annual-α\nset label-color 17
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

PLOT
1186
483
1546
618
count companies with [point-of-Sharing = 0]
days
NIL
0.0
240.0
0.0
3.0
true
true
"" ""
PENS
"0" 1.0 0 -13791810 true "" "plot count companies with [point-of-Sharing = 0]"

BUTTON
253
550
403
600
number of employees
set label n\nset label-color green
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

TEXTBOX
25
6
235
47
1. Select \"variability\" and \"scenario\" (click 'Setup' to view result)\n** Scenario No.0 'No sharing (default)'
11
0.0
1

TEXTBOX
25
205
175
223
2. Launch the model
11
0.0
1

TEXTBOX
20
280
245
321
3. If necessary, make more detailed settings here and Launch the model again.
11
0.0
1

TEXTBOX
265
465
675
491
4. After running, pressing buttons for viewing each the results.
11
0.0
1

TEXTBOX
110
400
250
470
After pressing the setup button, you can check the initial settings displayed in the command center.
11
0.0
1

CHOOSER
20
115
140
160
distributionScenario
distributionScenario
0 1 2 3
1

TEXTBOX
1195
15
1865
95
＜富の再分配シナリオ＞\n0.特に分配はせず\n1. 貧乏企業数と同数の金持ち企業が集まって、貧乏企業一社あたりdividend2分ずつのポイントを分配する。\n2. 貧乏企業数の1/2の金持ち企業が集まって、貧乏企業一社あたりdividend2分ずつのポイントを分配する。\n3. 貧乏企業数の1/3の金持ち企業が集まって、貧乏企業一社あたりdividend2分ずつのポイントを分配する。
11
0.0
1

PLOT
1185
190
1595
310
duty
days
NIL
0.0
241.0
0.0
10.0
true
true
"" ""
PENS
"sum [duty]" 1.0 1 -16777216 true "" "plotxy ticks sum [duty] of companies"

MONITOR
10
645
230
690
NIL
sum [Total-duty] of companies
0
1
11

BUTTON
255
610
405
655
Total-duty
set label Total-duty\nset label-color yellow
NIL
1
T
TURTLE
NIL
NIL
NIL
NIL
1

BUTTON
185
225
240
270
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
20
165
230
198
dividend
dividend
1
101
0.0
1
1
NIL
HORIZONTAL

TEXTBOX
1195
100
1745
181
＜削除シナリオ＞\n1.もしもポイントを全く持っていない企業があったなら、一番の金持ちが一企業あたり2%のポイントを分配する。\n2.もしもポイントを全く持っていない企業があったなら、一番の金持ちが一企業あたり5%のポイントを分配する。\n3.もしもネットワーク全体の1/3のポイントを所持する金持ちが存在したならば、その所持金の1/3の富をポイントを全く持っていない企業に分配する。\n4. スライダーn-millionaire2数の金持ち企業が集まって、貧乏企業一社あたりスライダーのdividend2分ずつのポイントを分配する。
11
5.0
1

MONITOR
10
690
230
735
NIL
sum [Total-workload] of companies
0
1
11

MONITOR
10
510
230
555
NIL
int sum [result2] of companies
17
1
11

MONITOR
10
740
230
785
NIL
sum [Total-θt-plus] of companies
17
1
11

MONITOR
10
785
230
830
NIL
sum [Total-θt-minus] of companies
17
1
11

INPUTBOX
145
100
245
160
RL-who-list-str
\"2\"
1
0
String

@#$#@#$#@
# P2P human resource allocation

## Model Scope

The model seeks  ways for **companies to level employee working hours without affecting sales by sharing employees between companies**.

>This is expected to lead to greater employment stability over time. We introduce **a new inter-company, peer-to-peer (P2P), human resource sharing platform** through which companies in idle periods can offer their employees to companies in busy periods using an automated negotiation technology.

## Concept model
### Agent Slection
**The main agent type is "company agent" that belongs to turtle.** The company agents’ goal is to ensure that employees have adequate work and minimal overwork.

### Factors Affecting Agents (environments)
External factors that affect corporate agents include the “total working hours per day (αt)” for work ordered by clients, which varies from day to day.

### Agent Action and Interaction
In idle periods, employees transform into idle resources, and they can become liabilities to companies if they are not properly utilized. In busy periods, an insufficient number of employees can result in an inability to complete the required work. We need to resolve this problem.

>**(total working hours per day [αt]) - (standard working hours per day) = (overtime/idle working hours per day [βt])**

To offset the “overtime/idle working hours per day [βt],” the company agents share their employees with other companies.

 **Agents from companies experiencing “busy periods” and “idle periods” negotiate and exchange.** “sharing points” and employees to offset “working hours of shortage or overage per day [βt]” of that day. The agent variable “status” is determined from the “overtime/idle working hours per day [βt],” which is determined by the “total working hours per day [αt]” that changes every day.
Determination of “status”:
>if (βt ≥ γ), status = “busy period,”
if (βt ≤ -γ), status = “idle period,”
if (|βt| < γ), status = “normal period.”

[γ] = Prescribed working hours (8 hours per person · fixed)

### Agent Properties
**main Properties**
>[αt] = total working hours per day (fluctuates daily)
[βt] = overtime/idle working hours per day
[β(t-1)] = carry-over working hours from the previous day
[δt] = overtime working hours per person ·  (maximum is selected with the slider · calculated after share negotiation · initial value 0)
[θt] = number of shared employees (determined during negotiation: initial value is 0; value is positive if borrowing employees from other companies; value is negative if lending employees to other companies)
[n] = number of employees (fixed)
[point-of-sharing] = a virtual currency (sharing point) in such a way that the rate is always constant (1P per person)
[status] = “busy” “idle” “normal”

**Evaluation Properties**
>[result] = Σ[t=0,240]|βt / n|    Total value of “busyness and idleness per person per year”
[totalβ] = Σ[t=0,240]|βt|
[totalθ] = Σ[t=0,240]|θt|

**Other Properties**
>[Annual-α] = total working hours per year (fixed) calculated from (n × γ ×240);
[Monthly-α] =  total working hours per month (fluctuating);
[weekly-α] = total working hours per week (fluctuating);

### Order of Events
The main action of the company agent is to repeat steps 1) to 4) daily (ticks):
Determine αt for that day.

>**1.** If the status is idle (or busy), choose another company agent whose status is the opposite, negotiate, and send (receive) employees if possible.
**2.** Complete the αt of the day, do overtime work if necessary.
**3.** Plan to carry over any unfinished work into the next day.
**4.** Increase one tick (end the day).


### Evaluation Criteria
The objective is to level employees' working hours by the proposed method, and the evaluation criterion is the total value of “busyness and idleness per person per year” in all companies.

>Total value of “busyness and idleness per person per year” in all companies (the smaller, the better)
**Σ[C=0,17][result]**
c = total number of companies (c=17 in our experiments)


## Internal model
The variable βt is the overtime/idle working hours per day (initial value 0). It is calculated from a formula that shows that (overtime/idle working hours per day) is ([αt] plus carry-over working hours from the day before) minus (total working hours of all employees including overtime hours and the work time of shared employees).

The formula is as follows:
>[βt] = ((αt) + (max(0,β(t-1))) - ((n * γ) + (N * δt) + (θt * γ))
[αt] = total working hours per day (fluctuates daily)
[max(0,β(t-1))] = carry-over working hours from the previous day
[n] = number of employees (fixed)
[δt] = overtime working hours per person (maximum 30 minutes · calculated after share negotiation · initial value 0)
[θt] = number of shared employees (determined during negotiation: initial value is 0; value is positive if borrowing employees from other companies; value is negative if lending employees to other companies)
[γ] = standard working hours (8 hours per person fixed)

θt, determined during the negotiation between an idle company agent and a busy company agent and is set to the minimum value of the following: the number of idle employees of the idle company; the number of extra workers needed by the busy company; the number of sharing points owned by the busy company.

δt is obtained during the overtime calculation process of the agent of the company in a busy or normal period. In the case of an idle period, δt= 0. If the numerical value of the following formula is less than .5 (30 minutes), use this value for δt:

>**((αt) + (max(0,β(t-1))) - ((n * γ) + (θt * γ)) / n**

If the numerical value of the above formula is greater than or equal to .5 (30 minutes), then δt = 0.5. The portion exceeding 30 minutes is carried over into the next day and processed when calculating β(t+1) for that day.

Next, we consider annual, monthly, and weekly working hours,
V = cubic root of “volatility rate” - 1.00 (fixed).
Total working hours (per month, week, day) are varied by V and a random number and calculated from the following equations 1) to 3), where random (x) is a function representing a random number from 0 to x in NetLogo.

>[monthly-α] = annual-α／12 + random (V × annual-α／6) − V × annual-α／12)
[weekly-α] = monthly- α／4 + random (V × monthly- α／2) − V × monthly-α／4
[αt]= weekly-α／5 + random (V × weekly-α／2.5) – V × weekly-α／5

t = days (240 ticks per year - initial value 0)
One week is five days (Monday–Friday); one month is four weeks; and one year is twelve months (no holidays).


## Evaluation scenario
Using the scenarios presented in this section, we analyze the behavior of inter-company human resource sharing in the artificial SME group.
>**Situation scenario (five) × Policy scenario (five)**

### Situation scenario(Variability)
The situation scenario is was analyzed using five different Variability rates.
>**Variability rate 1.00**
In this case, total working hours do not change at all. The working hours per day are constant throughout the year.

>**Variability rate 1.25**
Total working hours per day fluctuates.

>**Variability rate 1.50**
Total working hours per day fluctuates more.

>**Variability rate 1.75**
Total working hours per day fluctuates more and more.

>**Variability rate 2.00**
Total working hours per day fluctuates so tremendously.

### Policy scenario(Scenario)
In addition to Policy (0) in which company agents do not share any workers, we tested Policies (1) to (4), in which company agents do share workers. In all policies including Policy (0), overtime is possible, up to 30 minutes per person per day. A share cycle event occurs once per day. All company agents whose status is busy or idle can negotiate with idle (busy) company agents during one share cycle.

>**Policy (0) / No sharing (default).**
Employees complete total required working hours by themselves.

>**Policy (1) / Negotiate with one randomly selected company.**
 An agent from an idle (or busy) company randomly selects an agent from a company whose status is the opposite (busy or idle); they negotiate labor sharing. θt employees are exchanged with a sharing point of θt.

>**Policy (2) / Negotiate with selected company × S times.**
Repeat Policy (1) S times. S = number of negotiations(selected with the slider)

>**Policy (3) / Negotiate with selected company with the maximum value of |βt|.**
Each idle (or busy) company agent selects a company agent whose status is the opposite (busy or idle) and whose |βt| is at the maximum, and the agents negotiate labor sharing. θt employees are exchanged with the sharing point of θt.

>**Policy (4) / Negotiate with one company with the maximum value of |βt| × S times.**
Repeat Policy (3) S times.S = number of negotiations(selected with the slider)


## Inputs and Outputs
### Input data
The initial values of the company agents are  input from CSV data(input.csv).
Stores three agent property data:
>[n] [Point-of-Sharing] [Annual-α]

### Output data
It is assumed that the following variables are output for each ticks or the final value.
>[result] [totalβ] [totalθ] [Point-of-Sharing] [θt]

## User Interface
The interface of this model consists of three parts.

>**1. [Initial settings]**
 Chooser, Sliders, Buttons(setup, go)

>**2. [world][Switch display]**
Running and viewing each the results

>**3. [Visualized graphs]**

## Model Excution
Iinput.csv data should be placed on the same level as this net logo document.

>**1. Select "variability" and "scenario" (click 'Setup' to view result)**
 Scenario No.0 'No sharing (default)'

>**2. Launch the model**
Pressing 'setup' and 'go for 240 days'

>**3. If necessary, make more detailed settings here and launch the model again.**
'max-daily-overtime-minute'
'number-of-negotiations'
'input seed'
After pressing the setup button, you can check the initial settings displayed in the command center.

>**4. After running, pressing buttons for viewing each the results.**


## Credits and References
This model is a reconstituted version of “Introduction to Agent-Based Modeling” that was posted and presented at the International Conference (SCAI 2019).
SCAI 2019  http://www.iaiai.org/conference/aai2019/conference/scai-2019/
**Evaluating P2P human resource allocation strategies through multi-agent simulation**

The copyright of this program remains with the authors.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

company
false
0
Rectangle -7500403 true true 45 30 60 270
Rectangle -7500403 true true 225 30 240 270
Rectangle -7500403 true true 60 15 225 45
Rectangle -7500403 true true 90 45 105 225
Rectangle -7500403 true true 60 75 225 90
Rectangle -7500403 true true 135 45 150 225
Rectangle -7500403 true true 180 45 195 225
Rectangle -7500403 true true 60 120 225 135
Rectangle -7500403 true true 60 165 225 180
Rectangle -7500403 true true 60 210 240 225
Rectangle -7500403 true true 60 225 105 270
Rectangle -7500403 true true 180 225 225 270

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

house bungalow
false
0
Rectangle -7500403 true true 210 75 225 255
Rectangle -7500403 true true 90 135 210 255
Rectangle -16777216 true false 165 195 195 255
Line -16777216 false 210 135 210 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 150 75 150 150 75
Line -16777216 false 75 150 225 150
Line -16777216 false 195 120 225 150
Polygon -16777216 false false 165 195 150 195 180 165 210 195
Rectangle -16777216 true false 135 105 165 135

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

house efficiency
false
0
Rectangle -7500403 true true 180 90 195 195
Rectangle -7500403 true true 90 165 210 255
Rectangle -16777216 true false 165 195 195 255
Rectangle -16777216 true false 105 202 135 240
Polygon -7500403 true true 225 165 75 165 150 90
Line -16777216 false 75 165 225 165

house ranch
false
0
Rectangle -7500403 true true 270 120 285 255
Rectangle -7500403 true true 15 180 270 255
Polygon -7500403 true true 0 180 300 180 240 135 60 135 0 180
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 45 195 105 240
Rectangle -16777216 true false 195 195 255 240
Line -7500403 true 75 195 75 240
Line -7500403 true 225 195 225 240
Line -16777216 false 270 180 270 255
Line -16777216 false 0 180 300 180

house two story
false
0
Polygon -7500403 true true 2 180 227 180 152 150 32 150
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 75 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 90 150 135 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Rectangle -7500403 true true 15 180 75 255
Polygon -7500403 true true 60 135 285 135 240 90 105 90
Line -16777216 false 75 135 75 180
Rectangle -16777216 true false 30 195 93 240
Line -16777216 false 60 135 285 135
Line -16777216 false 255 105 285 135
Line -16777216 false 0 180 75 180
Line -7500403 true 60 195 60 240
Line -7500403 true 154 195 154 255

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-runtime(再生しない)" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>[βt] of company 0</metric>
    <metric>[βt] of company 1</metric>
    <metric>[βt] of company 2</metric>
    <metric>[βt] of company 3</metric>
    <metric>[βt] of company 4</metric>
    <metric>[βt] of company 5</metric>
    <metric>[βt] of company 6</metric>
    <metric>[βt] of company 7</metric>
    <metric>[βt] of company 8</metric>
    <metric>[βt] of company 9</metric>
    <metric>[βt] of company 10</metric>
    <metric>[βt] of company 11</metric>
    <metric>[βt] of company 12</metric>
    <metric>[βt] of company 13</metric>
    <metric>[βt] of company 14</metric>
    <metric>[βt] of company 15</metric>
    <metric>[βt] of company 16</metric>
    <metric>[θt] of company 0</metric>
    <metric>[θt] of company 1</metric>
    <metric>[θt] of company 2</metric>
    <metric>[θt] of company 3</metric>
    <metric>[θt] of company 4</metric>
    <metric>[θt] of company 5</metric>
    <metric>[θt] of company 6</metric>
    <metric>[θt] of company 7</metric>
    <metric>[θt] of company 8</metric>
    <metric>[θt] of company 9</metric>
    <metric>[θt] of company 10</metric>
    <metric>[θt] of company 11</metric>
    <metric>[θt] of company 12</metric>
    <metric>[θt] of company 13</metric>
    <metric>[θt] of company 14</metric>
    <metric>[θt] of company 15</metric>
    <metric>[θt] of company 16</metric>
    <metric>[duty] of company 0</metric>
    <metric>[duty] of company 1</metric>
    <metric>[duty] of company 2</metric>
    <metric>[duty] of company 3</metric>
    <metric>[duty] of company 4</metric>
    <metric>[duty] of company 5</metric>
    <metric>[duty] of company 6</metric>
    <metric>[duty] of company 7</metric>
    <metric>[duty] of company 8</metric>
    <metric>[duty] of company 9</metric>
    <metric>[duty] of company 10</metric>
    <metric>[duty] of company 11</metric>
    <metric>[duty] of company 12</metric>
    <metric>[duty] of company 13</metric>
    <metric>[duty] of company 14</metric>
    <metric>[duty] of company 15</metric>
    <metric>[duty] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1"/>
      <value value="1.25"/>
      <value value="1.5"/>
      <value value="1.75"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="1" step="1" last="100"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_C" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="scenario" first="1" step="1" last="2"/>
    <steppedValueSet variable="distributionScenario" first="0" step="1" last="3"/>
    <steppedValueSet variable="dividend" first="1" step="2" last="101"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_Z" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="scenario" first="0" step="1" last="2"/>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_Y" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="scenario" first="0" step="1" last="2"/>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment201910_D" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="101"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_E" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="41"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_X" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="scenario" first="0" step="1" last="2"/>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#F-[result] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>[result] of company 0</metric>
    <metric>[result] of company 1</metric>
    <metric>[result] of company 2</metric>
    <metric>[result] of company 3</metric>
    <metric>[result] of company 4</metric>
    <metric>[result] of company 5</metric>
    <metric>[result] of company 6</metric>
    <metric>[result] of company 7</metric>
    <metric>[result] of company 8</metric>
    <metric>[result] of company 9</metric>
    <metric>[result] of company 10</metric>
    <metric>[result] of company 11</metric>
    <metric>[result] of company 12</metric>
    <metric>[result] of company 13</metric>
    <metric>[result] of company 14</metric>
    <metric>[result] of company 15</metric>
    <metric>[result] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="###不要###G-[result2] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [result2] of companies</metric>
    <metric>[result2] of company 0</metric>
    <metric>[result2] of company 1</metric>
    <metric>[result2] of company 2</metric>
    <metric>[result2] of company 3</metric>
    <metric>[result2] of company 4</metric>
    <metric>[result2] of company 5</metric>
    <metric>[result2] of company 6</metric>
    <metric>[result2] of company 7</metric>
    <metric>[result2] of company 8</metric>
    <metric>[result2] of company 9</metric>
    <metric>[result2] of company 10</metric>
    <metric>[result2] of company 11</metric>
    <metric>[result2] of company 12</metric>
    <metric>[result2] of company 13</metric>
    <metric>[result2] of company 14</metric>
    <metric>[result2] of company 15</metric>
    <metric>[result2] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#H-[Total-duty] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>[Total-duty] of company 0</metric>
    <metric>[Total-duty] of company 1</metric>
    <metric>[Total-duty] of company 2</metric>
    <metric>[Total-duty] of company 3</metric>
    <metric>[Total-duty] of company 4</metric>
    <metric>[Total-duty] of company 5</metric>
    <metric>[Total-duty] of company 6</metric>
    <metric>[Total-duty] of company 7</metric>
    <metric>[Total-duty] of company 8</metric>
    <metric>[Total-duty] of company 9</metric>
    <metric>[Total-duty] of company 10</metric>
    <metric>[Total-duty] of company 11</metric>
    <metric>[Total-duty] of company 12</metric>
    <metric>[Total-duty] of company 13</metric>
    <metric>[Total-duty] of company 14</metric>
    <metric>[Total-duty] of company 15</metric>
    <metric>[Total-duty] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="###不要###I-[Total-θ] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>[Total-θ] of company 0</metric>
    <metric>[Total-θ] of company 1</metric>
    <metric>[Total-θ] of company 2</metric>
    <metric>[Total-θ] of company 3</metric>
    <metric>[Total-θ] of company 4</metric>
    <metric>[Total-θ] of company 5</metric>
    <metric>[Total-θ] of company 6</metric>
    <metric>[Total-θ] of company 7</metric>
    <metric>[Total-θ] of company 8</metric>
    <metric>[Total-θ] of company 9</metric>
    <metric>[Total-θ] of company 10</metric>
    <metric>[Total-θ] of company 11</metric>
    <metric>[Total-θ] of company 12</metric>
    <metric>[Total-θ] of company 13</metric>
    <metric>[Total-θ] of company 14</metric>
    <metric>[Total-θ] of company 15</metric>
    <metric>[Total-θ] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_ZA" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="scenario" first="0" step="1" last="2"/>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202001_ZB" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="2"/>
    </enumeratedValueSet>
    <steppedValueSet variable="scenario" first="0" step="1" last="2"/>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#F0-[result] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>[result] of company 0</metric>
    <metric>[result] of company 1</metric>
    <metric>[result] of company 2</metric>
    <metric>[result] of company 3</metric>
    <metric>[result] of company 4</metric>
    <metric>[result] of company 5</metric>
    <metric>[result] of company 6</metric>
    <metric>[result] of company 7</metric>
    <metric>[result] of company 8</metric>
    <metric>[result] of company 9</metric>
    <metric>[result] of company 10</metric>
    <metric>[result] of company 11</metric>
    <metric>[result] of company 12</metric>
    <metric>[result] of company 13</metric>
    <metric>[result] of company 14</metric>
    <metric>[result] of company 15</metric>
    <metric>[result] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="###不要###G0-[result2] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [result2] of companies</metric>
    <metric>[result2] of company 0</metric>
    <metric>[result2] of company 1</metric>
    <metric>[result2] of company 2</metric>
    <metric>[result2] of company 3</metric>
    <metric>[result2] of company 4</metric>
    <metric>[result2] of company 5</metric>
    <metric>[result2] of company 6</metric>
    <metric>[result2] of company 7</metric>
    <metric>[result2] of company 8</metric>
    <metric>[result2] of company 9</metric>
    <metric>[result2] of company 10</metric>
    <metric>[result2] of company 11</metric>
    <metric>[result2] of company 12</metric>
    <metric>[result2] of company 13</metric>
    <metric>[result2] of company 14</metric>
    <metric>[result2] of company 15</metric>
    <metric>[result2] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#H0-[Total-duty] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>[Total-duty] of company 0</metric>
    <metric>[Total-duty] of company 1</metric>
    <metric>[Total-duty] of company 2</metric>
    <metric>[Total-duty] of company 3</metric>
    <metric>[Total-duty] of company 4</metric>
    <metric>[Total-duty] of company 5</metric>
    <metric>[Total-duty] of company 6</metric>
    <metric>[Total-duty] of company 7</metric>
    <metric>[Total-duty] of company 8</metric>
    <metric>[Total-duty] of company 9</metric>
    <metric>[Total-duty] of company 10</metric>
    <metric>[Total-duty] of company 11</metric>
    <metric>[Total-duty] of company 12</metric>
    <metric>[Total-duty] of company 13</metric>
    <metric>[Total-duty] of company 14</metric>
    <metric>[Total-duty] of company 15</metric>
    <metric>[Total-duty] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="###不要###I0-[Total-θ] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>[Total-θ] of company 0</metric>
    <metric>[Total-θ] of company 1</metric>
    <metric>[Total-θ] of company 2</metric>
    <metric>[Total-θ] of company 3</metric>
    <metric>[Total-θ] of company 4</metric>
    <metric>[Total-θ] of company 5</metric>
    <metric>[Total-θ] of company 6</metric>
    <metric>[Total-θ] of company 7</metric>
    <metric>[Total-θ] of company 8</metric>
    <metric>[Total-θ] of company 9</metric>
    <metric>[Total-θ] of company 10</metric>
    <metric>[Total-θ] of company 11</metric>
    <metric>[Total-θ] of company 12</metric>
    <metric>[Total-θ] of company 13</metric>
    <metric>[Total-θ] of company 14</metric>
    <metric>[Total-θ] of company 15</metric>
    <metric>[Total-θ] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#J-[Total-θt-plus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>[Total-θt-plus] of company 0</metric>
    <metric>[Total-θt-plus] of company 1</metric>
    <metric>[Total-θt-plus] of company 2</metric>
    <metric>[Total-θt-plus] of company 3</metric>
    <metric>[Total-θt-plus] of company 4</metric>
    <metric>[Total-θt-plus] of company 5</metric>
    <metric>[Total-θt-plus] of company 6</metric>
    <metric>[Total-θt-plus] of company 7</metric>
    <metric>[Total-θt-plus] of company 8</metric>
    <metric>[Total-θt-plus] of company 9</metric>
    <metric>[Total-θt-plus] of company 10</metric>
    <metric>[Total-θt-plus] of company 11</metric>
    <metric>[Total-θt-plus] of company 12</metric>
    <metric>[Total-θt-plus] of company 13</metric>
    <metric>[Total-θt-plus] of company 14</metric>
    <metric>[Total-θt-plus] of company 15</metric>
    <metric>[Total-θt-plus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#K-[Total-θt-minus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <metric>[Total-θt-minus] of company 0</metric>
    <metric>[Total-θt-minus] of company 1</metric>
    <metric>[Total-θt-minus] of company 2</metric>
    <metric>[Total-θt-minus] of company 3</metric>
    <metric>[Total-θt-minus] of company 4</metric>
    <metric>[Total-θt-minus] of company 5</metric>
    <metric>[Total-θt-minus] of company 6</metric>
    <metric>[Total-θt-minus] of company 7</metric>
    <metric>[Total-θt-minus] of company 8</metric>
    <metric>[Total-θt-minus] of company 9</metric>
    <metric>[Total-θt-minus] of company 10</metric>
    <metric>[Total-θt-minus] of company 11</metric>
    <metric>[Total-θt-minus] of company 12</metric>
    <metric>[Total-θt-minus] of company 13</metric>
    <metric>[Total-θt-minus] of company 14</metric>
    <metric>[Total-θt-minus] of company 15</metric>
    <metric>[Total-θt-minus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#J0-[Total-θt-plus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>[Total-θt-plus] of company 0</metric>
    <metric>[Total-θt-plus] of company 1</metric>
    <metric>[Total-θt-plus] of company 2</metric>
    <metric>[Total-θt-plus] of company 3</metric>
    <metric>[Total-θt-plus] of company 4</metric>
    <metric>[Total-θt-plus] of company 5</metric>
    <metric>[Total-θt-plus] of company 6</metric>
    <metric>[Total-θt-plus] of company 7</metric>
    <metric>[Total-θt-plus] of company 8</metric>
    <metric>[Total-θt-plus] of company 9</metric>
    <metric>[Total-θt-plus] of company 10</metric>
    <metric>[Total-θt-plus] of company 11</metric>
    <metric>[Total-θt-plus] of company 12</metric>
    <metric>[Total-θt-plus] of company 13</metric>
    <metric>[Total-θt-plus] of company 14</metric>
    <metric>[Total-θt-plus] of company 15</metric>
    <metric>[Total-θt-plus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="#K0-[Total-θt-minus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <metric>[Total-θt-minus] of company 0</metric>
    <metric>[Total-θt-minus] of company 1</metric>
    <metric>[Total-θt-minus] of company 2</metric>
    <metric>[Total-θt-minus] of company 3</metric>
    <metric>[Total-θt-minus] of company 4</metric>
    <metric>[Total-θt-minus] of company 5</metric>
    <metric>[Total-θt-minus] of company 6</metric>
    <metric>[Total-θt-minus] of company 7</metric>
    <metric>[Total-θt-minus] of company 8</metric>
    <metric>[Total-θt-minus] of company 9</metric>
    <metric>[Total-θt-minus] of company 10</metric>
    <metric>[Total-θt-minus] of company 11</metric>
    <metric>[Total-θt-minus] of company 12</metric>
    <metric>[Total-θt-minus] of company 13</metric>
    <metric>[Total-θt-minus] of company 14</metric>
    <metric>[Total-θt-minus] of company 15</metric>
    <metric>[Total-θt-minus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##F-[result] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>[result] of company 0</metric>
    <metric>[result] of company 1</metric>
    <metric>[result] of company 2</metric>
    <metric>[result] of company 3</metric>
    <metric>[result] of company 4</metric>
    <metric>[result] of company 5</metric>
    <metric>[result] of company 6</metric>
    <metric>[result] of company 7</metric>
    <metric>[result] of company 8</metric>
    <metric>[result] of company 9</metric>
    <metric>[result] of company 10</metric>
    <metric>[result] of company 11</metric>
    <metric>[result] of company 12</metric>
    <metric>[result] of company 13</metric>
    <metric>[result] of company 14</metric>
    <metric>[result] of company 15</metric>
    <metric>[result] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##H-[Total-duty] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>[Total-duty] of company 0</metric>
    <metric>[Total-duty] of company 1</metric>
    <metric>[Total-duty] of company 2</metric>
    <metric>[Total-duty] of company 3</metric>
    <metric>[Total-duty] of company 4</metric>
    <metric>[Total-duty] of company 5</metric>
    <metric>[Total-duty] of company 6</metric>
    <metric>[Total-duty] of company 7</metric>
    <metric>[Total-duty] of company 8</metric>
    <metric>[Total-duty] of company 9</metric>
    <metric>[Total-duty] of company 10</metric>
    <metric>[Total-duty] of company 11</metric>
    <metric>[Total-duty] of company 12</metric>
    <metric>[Total-duty] of company 13</metric>
    <metric>[Total-duty] of company 14</metric>
    <metric>[Total-duty] of company 15</metric>
    <metric>[Total-duty] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##F0-[result] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>[result] of company 0</metric>
    <metric>[result] of company 1</metric>
    <metric>[result] of company 2</metric>
    <metric>[result] of company 3</metric>
    <metric>[result] of company 4</metric>
    <metric>[result] of company 5</metric>
    <metric>[result] of company 6</metric>
    <metric>[result] of company 7</metric>
    <metric>[result] of company 8</metric>
    <metric>[result] of company 9</metric>
    <metric>[result] of company 10</metric>
    <metric>[result] of company 11</metric>
    <metric>[result] of company 12</metric>
    <metric>[result] of company 13</metric>
    <metric>[result] of company 14</metric>
    <metric>[result] of company 15</metric>
    <metric>[result] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##H0-[Total-duty] of company" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>[Total-duty] of company 0</metric>
    <metric>[Total-duty] of company 1</metric>
    <metric>[Total-duty] of company 2</metric>
    <metric>[Total-duty] of company 3</metric>
    <metric>[Total-duty] of company 4</metric>
    <metric>[Total-duty] of company 5</metric>
    <metric>[Total-duty] of company 6</metric>
    <metric>[Total-duty] of company 7</metric>
    <metric>[Total-duty] of company 8</metric>
    <metric>[Total-duty] of company 9</metric>
    <metric>[Total-duty] of company 10</metric>
    <metric>[Total-duty] of company 11</metric>
    <metric>[Total-duty] of company 12</metric>
    <metric>[Total-duty] of company 13</metric>
    <metric>[Total-duty] of company 14</metric>
    <metric>[Total-duty] of company 15</metric>
    <metric>[Total-duty] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##J-[Total-θt-plus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>[Total-θt-plus] of company 0</metric>
    <metric>[Total-θt-plus] of company 1</metric>
    <metric>[Total-θt-plus] of company 2</metric>
    <metric>[Total-θt-plus] of company 3</metric>
    <metric>[Total-θt-plus] of company 4</metric>
    <metric>[Total-θt-plus] of company 5</metric>
    <metric>[Total-θt-plus] of company 6</metric>
    <metric>[Total-θt-plus] of company 7</metric>
    <metric>[Total-θt-plus] of company 8</metric>
    <metric>[Total-θt-plus] of company 9</metric>
    <metric>[Total-θt-plus] of company 10</metric>
    <metric>[Total-θt-plus] of company 11</metric>
    <metric>[Total-θt-plus] of company 12</metric>
    <metric>[Total-θt-plus] of company 13</metric>
    <metric>[Total-θt-plus] of company 14</metric>
    <metric>[Total-θt-plus] of company 15</metric>
    <metric>[Total-θt-plus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##K-[Total-θt-minus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <metric>[Total-θt-minus] of company 0</metric>
    <metric>[Total-θt-minus] of company 1</metric>
    <metric>[Total-θt-minus] of company 2</metric>
    <metric>[Total-θt-minus] of company 3</metric>
    <metric>[Total-θt-minus] of company 4</metric>
    <metric>[Total-θt-minus] of company 5</metric>
    <metric>[Total-θt-minus] of company 6</metric>
    <metric>[Total-θt-minus] of company 7</metric>
    <metric>[Total-θt-minus] of company 8</metric>
    <metric>[Total-θt-minus] of company 9</metric>
    <metric>[Total-θt-minus] of company 10</metric>
    <metric>[Total-θt-minus] of company 11</metric>
    <metric>[Total-θt-minus] of company 12</metric>
    <metric>[Total-θt-minus] of company 13</metric>
    <metric>[Total-θt-minus] of company 14</metric>
    <metric>[Total-θt-minus] of company 15</metric>
    <metric>[Total-θt-minus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="dividend" first="1" step="2" last="12"/>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##J0-[Total-θt-plus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>[Total-θt-plus] of company 0</metric>
    <metric>[Total-θt-plus] of company 1</metric>
    <metric>[Total-θt-plus] of company 2</metric>
    <metric>[Total-θt-plus] of company 3</metric>
    <metric>[Total-θt-plus] of company 4</metric>
    <metric>[Total-θt-plus] of company 5</metric>
    <metric>[Total-θt-plus] of company 6</metric>
    <metric>[Total-θt-plus] of company 7</metric>
    <metric>[Total-θt-plus] of company 8</metric>
    <metric>[Total-θt-plus] of company 9</metric>
    <metric>[Total-θt-plus] of company 10</metric>
    <metric>[Total-θt-plus] of company 11</metric>
    <metric>[Total-θt-plus] of company 12</metric>
    <metric>[Total-θt-plus] of company 13</metric>
    <metric>[Total-θt-plus] of company 14</metric>
    <metric>[Total-θt-plus] of company 15</metric>
    <metric>[Total-θt-plus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="##K0-[Total-θt-minus] of companies" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt;= 240</exitCondition>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <metric>[Total-θt-minus] of company 0</metric>
    <metric>[Total-θt-minus] of company 1</metric>
    <metric>[Total-θt-minus] of company 2</metric>
    <metric>[Total-θt-minus] of company 3</metric>
    <metric>[Total-θt-minus] of company 4</metric>
    <metric>[Total-θt-minus] of company 5</metric>
    <metric>[Total-θt-minus] of company 6</metric>
    <metric>[Total-θt-minus] of company 7</metric>
    <metric>[Total-θt-minus] of company 8</metric>
    <metric>[Total-θt-minus] of company 9</metric>
    <metric>[Total-θt-minus] of company 10</metric>
    <metric>[Total-θt-minus] of company 11</metric>
    <metric>[Total-θt-minus] of company 12</metric>
    <metric>[Total-θt-minus] of company 13</metric>
    <metric>[Total-θt-minus] of company 14</metric>
    <metric>[Total-θt-minus] of company 15</metric>
    <metric>[Total-θt-minus] of company 16</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dividend">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202602_Z_1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="my-seed">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment202602_Z" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>int sum [result] of companies</metric>
    <metric>int sum [Total-β] of companies</metric>
    <metric>int sum [Total-θ] of companies</metric>
    <metric>int sum [Total-duty] of companies</metric>
    <metric>int sum [Total-workload] of companies</metric>
    <metric>int sum [result2] of companies</metric>
    <metric>int sum [Total-θt-plus] of companies</metric>
    <metric>int sum [Total-θt-minus] of companies</metric>
    <enumeratedValueSet variable="variability">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributionScenario">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="my-seed" first="0" step="1" last="99"/>
    <enumeratedValueSet variable="max-daily-overtime-minute">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-negotiations">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
