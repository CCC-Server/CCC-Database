-- 홀로판타지 (커스텀)
-- SetCode: 0xc44
local s,id=GetID()
function s.initial_effect(c)
  c:EnableReviveLimit()
  -- 싱크로 소환: 튜너 1 + 비튜너 1, 단 이 카드의 싱크로 재료로 "홀로판타지"를 튜너로 취급
  -- Cyber Slash 방식의 추가 소재 필터 사용
  Synchro.AddProcedure(c,nil,1,1,Synchro.NonTuner(nil),1,1,s.matfilter)

  -- ① 싱크로 소환 성공시 주사위 2회 → 합계에 따라 덱에서 세트
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_DICE) -- CATEGORY_TOFIELD는 존재하지 않음
  e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
  e1:SetCode(EVENT_SPSUMMON_SUCCESS)
  e1:SetProperty(EFFECT_FLAG_DELAY)
  e1:SetCountLimit(1,id)
  e1:SetCondition(s.sumcon)
  e1:SetTarget(s.sumtg)
  e1:SetOperation(s.sumop)
  c:RegisterEffect(e1)

  -- ② (듀얼 중 1번) 자신이 주사위를 던졌고, 자신 필드/묘지에 이름 다른 필드 마법 3종 이상 있을 때
  -- 주사위 결과 중 1개를 7로 치환
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
  e2:SetCode(EVENT_TOSS_DICE)
  e2:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
  e2:SetOperation(s.dicereplace)
  c:RegisterEffect(e2)

  -- ③ (속공) 자신/상대 턴: 이 카드를 엑스트라로 되돌리고, GY의 "홀로판타지" 2장 특소 → 선택적으로 필드 1장 파괴
  local e3=Effect.CreateEffect(c)
  e3:SetDescription(aux.Stringid(id,2))
  e3:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
  e3:SetType(EFFECT_TYPE_QUICK_O)
  e3:SetCode(EVENT_FREE_CHAIN)
  e3:SetRange(LOCATION_MZONE)
  e3:SetHintTiming(0,TIMING_END_PHASE)
  e3:SetCountLimit(1,id+100)
  e3:SetCost(s.spcost)
  e3:SetTarget(s.sptg)
  e3:SetOperation(s.spop)
  c:RegisterEffect(e3)
end

-- 목록 등록(툴팁/호환)
s.listed_series={0xc44}

--------------------------------
-- 싱크로: 추가 소재 필터(튜너 취급)
--------------------------------
-- 이 카드의 싱크로 소환 시, 자신 필드의 "홀로판타지"를 튜너로 취급
function s.matfilter(c,scard,sumtype,tp)
  -- 일반적으로 싱크로 재료는 필드에 있어야 하므로 별도 위치 체크는 생략해도 무방하지만,
  -- 안전하게 컨트롤러/존 확인을 추가해둡니다.
  return c:IsSetCard(0xc44,scard,sumtype,tp) and c:IsControler(tp) and c:IsLocation(LOCATION_MZONE)
end

--------------------------------
-- ① 싱크로 소환 성공시
--------------------------------
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
  return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.setfilter_c44(c)
  return c:IsSetCard(0xc44) and (c:IsType(TYPE_SPELL) or c:IsType(TYPE_TRAP)) and c:IsSSetable()
end
function s.setfilter_countertrap(c)
  return c:IsType(TYPE_TRAP) and c:IsType(TYPE_COUNTER) and c:IsSSetable()
end
function s.sumtg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return true end
  Duel.SetOperationInfo(0,CATEGORY_DICE,nil,0,tp,2)
end
function s.sumop(e,tp,eg,ep,ev,re,r,rp)
  local d1,d2=Duel.TossDice(tp,2)
  local total=d1+d2
  if total<=7 then
    local g=Duel.GetMatchingGroup(s.setfilter_c44,tp,LOCATION_DECK,0,nil)
    if #g>0 then
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
      local sg=g:Select(tp,1,1,nil)
      if #sg>0 then
        Duel.SSet(tp,sg)
        Duel.ConfirmCards(1-tp,sg)
      end
    end
  else
    local g=Duel.GetMatchingGroup(s.setfilter_countertrap,tp,LOCATION_DECK,0,nil)
    if #g>0 then
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
      local sg=g:Select(tp,1,1,nil)
      if #sg>0 then
        Duel.SSet(tp,sg)
        Duel.ConfirmCards(1-tp,sg)
      end
    end
  end
end

--------------------------------
-- ② 주사위 결과 1개를 7로 치환 (듀얼 중 1번)
--------------------------------
local function countDistinctFieldSpells(tp)
  local g=Group.CreateGroup()
  local fz=Duel.GetMatchingGroup(function(c) return c:IsType(TYPE_FIELD) and c:IsFaceup() end,tp,LOCATION_FZONE,0,nil)
  local gy=Duel.GetMatchingGroup(function(c) return c:IsType(TYPE_FIELD) and c:IsLocation(LOCATION_GRAVE) end,tp,LOCATION_GRAVE,0,nil)
  g:Merge(fz) g:Merge(gy)
  local names,ct={},0
  for tc in g:Iter() do
    local code=tc:GetOriginalCode()
    if not names[code] then names[code]=true ct=ct+1 end
  end
  return ct
end

function s.dicereplace(e,tp,eg,ep,ev,re,r,rp)
  -- 자신이 굴린 주사위만 개입
  if rp~=tp then return end
  -- 듀얼 중 1번
  if Duel.GetFlagEffect(tp,id)>0 then return end
  -- 필드/묘지에 이름 다른 필드마법 3종 이상
  if countDistinctFieldSpells(tp)<3 then return end

  local res={Duel.GetDiceResult()}
  if #res==0 then return end
  if not Duel.SelectYesNo(tp,aux.Stringid(id,3)) then return end

  -- 선택한 하나를 7로 치환
  local opts={}
  for i=1,#res do opts[i]=i end
  Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,4))
  local sel=Duel.AnnounceNumber(tp,table.unpack(opts))
  res[sel]=7
  Duel.SetDiceResult(table.unpack(res))

  -- 듀얼 전체 1회 소모(리셋 없음)
  Duel.RegisterFlagEffect(tp,id,0,0,1)
end

--------------------------------
-- ③ 퀵: 자신을 엑스트라로 되돌리고, GY의 "홀로판타지" 2장 특소 → 선택 파괴
--------------------------------
function s.spfilter(c,e,tp)
  return c:IsSetCard(0xc44) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
  local c=e:GetHandler()
  if chk==0 then return c:IsAbleToExtraAsCost() end
  Duel.SendtoDeck(c,nil,SEQ_DECKTOP,REASON_COST) -- 엑스트라로 돌아감(엑스트라 몬스터는 face-up)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
      and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_GRAVE,0,2,nil,e,tp)
  end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE)
  Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,0,LOCATION_ONFIELD)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
  if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_GRAVE,0,2,2,nil,e,tp)
  if #g<2 then return end
  if Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)>0 then
    local dg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
    if #dg>0 and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
      local sg=dg:Select(tp,1,1,nil)
      if #sg>0 then
        Duel.HintSelection(sg,true)
        Duel.Destroy(sg,REASON_EFFECT)
      end
    end
  end
end
