--Holophantasy Quick-Play (Custom)
local s,id=GetID()
function s.initial_effect(c)
  --① Activate: GY의 "홀로판타지" 다수 → 덱으로 / 그 후 상대 필드 1장 덱으로 / 정확히 3장의 "홀로판타지" 필드마법이면 드로우 1
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
  e1:SetCountLimit(1,id) 
  e1:SetTarget(s.target)
  e1:SetOperation(s.activate)
  c:RegisterEffect(e1)

  --② GY: 상대가 몬스터를 특수 소환했을 때, 이 카드를 제외 → "홀로판타지"를 포함하여 싱크로 소환
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
  e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG2_CHECK_SIMULTANEOUS)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetRange(LOCATION_GRAVE)
  e2:SetCountLimit(1,{id,1})
  e2:SetCondition(s.spcon)
  e2:SetCost(s.spcost)
  e2:SetTarget(s.sctg)
  e2:SetOperation(s.scop)
  c:RegisterEffect(e2)
end
s.listed_series={0xc44}

-------------------------------------------------
-- ① 발동 효과
-------------------------------------------------
function s.gyfilter(c,e)
  return c:IsSetCard(0xc44) and c:IsAbleToDeck() and c:IsCanBeEffectTarget(e) and c:IsLocation(LOCATION_GRAVE)
end
function s.holoFieldFilter(c)
  return c:IsSetCard(0xc44) and c:IsType(TYPE_FIELD)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
  if chkc then return false end
  local g=Duel.GetMatchingGroup(s.gyfilter,tp,LOCATION_GRAVE,0,nil,e)
  if chk==0 then return #g>0 end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
  local tg=g:Select(tp,1,#g,nil)
  Duel.SetTargetCard(tg)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,#tg,tp,LOCATION_GRAVE)
  Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_ONFIELD)
  Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
  local tg=Duel.GetTargetCards(e)
  if #tg==0 then return end
  local ct_hf=tg:FilterCount(s.holoFieldFilter,nil)
  local exact3=(ct_hf==3)
  local sent=Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
  if sent>0 then
    local og=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,nil)
    if #og>0 then
      Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
      local sg=og:Select(tp,1,1,nil)
      if #sg>0 then
        Duel.HintSelection(sg,true)
        Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
      end
    end
    if exact3 then
      Duel.BreakEffect()
      Duel.Draw(tp,1,REASON_EFFECT)
    end
  end
end

-------------------------------------------------
-- ② 묘지 발동: 싱크로 소환
-------------------------------------------------
-- 상대 필드에 몬스터가 특수 소환되었는지
function s.spconfilter(c,tp)
  return c:IsSummonPlayer(1-tp) and c:IsLocation(LOCATION_MZONE)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
  return eg:IsExists(s.spconfilter,1,nil,tp)
end
-- 코스트: 이 카드 제외
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
  Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

-- 싱크로 후보 확인 (자신 필드 + 반드시 홀로판타지 포함)
local function can_syn_with_holo(sc,mg)
  local holo=mg:Filter(Card.IsSetCard,nil,0xc44)
  for smat in aux.Next(holo) do
    if sc:IsSynchroSummonable(smat,mg) then return true end
  end
  return false
end
function s.scfilter(sc,mg) return can_syn_with_holo(sc,mg) end

function s.sctg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
    local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
    return Duel.IsExistingMatchingCard(s.scfilter,tp,LOCATION_EXTRA,0,1,nil,mg)
  end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.scop(e,tp,eg,ep,ev,re,r,rp)
  local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
  if #mg==0 then return end
  local g=Duel.GetMatchingGroup(s.scfilter,tp,LOCATION_EXTRA,0,nil,mg)
  if #g==0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local sc=g:Select(tp,1,1,nil):GetFirst()
  if not sc then return end
  -- 반드시 포함할 '홀로판타지' 소재 선택
  local smats=mg:Filter(function(c,scn,matg) return c:IsSetCard(0xc44) and scn:IsSynchroSummonable(c,matg) end,nil,sc,mg)
  if #smats==0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
  local smat=smats:Select(tp,1,1,nil):GetFirst()
  if not smat then return end
  Duel.SynchroSummon(tp,sc,smat,mg)
end
