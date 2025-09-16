--Holophantasy Quick-Play (Custom)
local s,id=GetID()
function s.initial_effect(c)
  --① Activate (패/세트에서 자유 발동) : GY의 "홀로판타지" 다수 대상 → 덱으로 / 그 후 상대 필드 1장 덱으로 / (대상 중 "홀로판타지" 필드마법 정확히 3장일 때 드로우 1)
  local e1=Effect.CreateEffect(c)
  e1:SetDescription(aux.Stringid(id,0))
  e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
  e1:SetType(EFFECT_TYPE_ACTIVATE)
  e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
  e1:SetCode(EVENT_FREE_CHAIN)
  e1:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
  e1:SetCountLimit(1,id) -- ① 하드 OPT
  e1:SetTarget(s.target)
  e1:SetOperation(s.activate)
  c:RegisterEffect(e1)

  --② GY에서: 상대 필드에 몬스터가 특수 소환되면, 이 카드를 제외하고 발동 → "홀로판타지"를 포함하여 자신 필드만으로 싱크로 소환
  local e2=Effect.CreateEffect(c)
  e2:SetDescription(aux.Stringid(id,1))
  e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
  e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
  e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG2_CHECK_SIMULTANEOUS)
  e2:SetCode(EVENT_SPSUMMON_SUCCESS)
  e2:SetRange(LOCATION_GRAVE)
  e2:SetCountLimit(1,{id,1}) -- ② 하드 OPT
  e2:SetCondition(s.spcon)
  e2:SetCost(s.spcost)
  e2:SetTarget(s.sptg)
  e2:SetOperation(s.spop)
  c:RegisterEffect(e2)
end
s.listed_series={0xc44}

-------------------------------------------------
-- ① 활성화 / 처리
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
  -- 임의 수(1~최대) 선택
  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
  local tg=g:Select(tp,1,#g,nil)
  Duel.SetTargetCard(tg)
  Duel.SetOperationInfo(0,CATEGORY_TODECK,tg,#tg,tp,LOCATION_GRAVE)
  -- 이후 상대 필드 1장도 덱으로 (가능 정보)
  Duel.SetPossibleOperationInfo(0,CATEGORY_TODECK,nil,1,1-tp,LOCATION_ONFIELD)
  -- 드로우 1 (조건 달성 시)
  Duel.SetPossibleOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
  local c=e:GetHandler()
  local tg=Duel.GetTargetCards(e)			   -- 아직 유효한 타깃만
  if #tg==0 then return end
  -- 드로우 조건 계산: "타깃으로 지정된 카드 중" '홀로판타지' 필드마법이 정확히 3장인가?
  local ct_hf=tg:FilterCount(s.holoFieldFilter,nil)
  local exact3=(ct_hf==3)
  -- 지정된 카드들을 덱으로 되돌림(섞어넣기)
  local sent=Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
  if sent>0 then
	-- 그 후, 상대 필드의 카드 1장을 덱으로 되돌림 (비표적 선택: 처리 시점에 선택)
	local og=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,0,LOCATION_ONFIELD,nil)
	if #og>0 then
	  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	  local sg=og:Select(tp,1,1,nil)
	  if #sg>0 then
		Duel.HintSelection(sg,true)
		Duel.SendtoDeck(sg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	  end
	end
	-- 추가: 정확히 3장의 "홀로판타지" 필드마법을 타깃으로 발동했다면 드로우 1
	if exact3 then
	  Duel.BreakEffect()
	  Duel.Draw(tp,1,REASON_EFFECT)
	end
  end
end

-------------------------------------------------
-- ② GY 트리거 / 코스트 / 싱크로 소환
-------------------------------------------------
-- 상대 필드에 몬스터가 특수 소환되었는지
function s.spconfilter(c,tp)
  return c:IsSummonPlayer(1-tp) and c:IsLocation(LOCATION_MZONE)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
  return eg:IsExists(s.spconfilter,1,nil,tp)
end
-- 코스트: 자신을 제외
function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then return e:GetHandler():IsAbleToRemoveAsCost() end
  Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end
-- 싱크로 가능한 후보를 "자신 필드 몬스터"만으로, 그리고 소재에 반드시 '홀로판타지' 포함으로 제한
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
  if chk==0 then
	local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
	local holo=mg:Filter(Card.IsSetCard,nil,0xc44)
	if #holo==0 then return false end
	-- 엑스트라 후보 중, 'holo'의 어느 한 장을 smat로 포함해 소환 가능한 싱크로가 있는가?
	return Duel.IsExistingMatchingCard(function(sc,mg1,mg2)
	  for hc in mg1:Iter() do
		if sc:IsSynchroSummonable(hc,mg2) then return true end
	  end
	  return false
	end,tp,LOCATION_EXTRA,0,nil,holo,mg)
  end
  Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
  local mg=Duel.GetMatchingGroup(Card.IsFaceup,tp,LOCATION_MZONE,0,nil)
  local holo=mg:Filter(Card.IsSetCard,nil,0xc44)
  if #holo==0 then return end
  -- 싱크로 후보 집합: '홀로' 중 하나를 반드시 포함해 소환 가능
  local sg=Duel.GetMatchingGroup(function(sc,mg1,mg2)
	for hc in mg1:Iter() do
	  if sc:IsSynchroSummonable(hc,mg2) then return true end
	end
	return false
  end,tp,LOCATION_EXTRA,0,nil,holo,mg)
  if #sg==0 then return end

  Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
  local sc=sg:Select(tp,1,1,nil):GetFirst()
  if not sc then return end
  -- 이 싱크로 소환에서 사용할 '반드시 포함할 홀로판타지 몬스터(smat)'를 선택
  local smats=holo:Filter(function(c,scn,matg) return scn:IsSynchroSummonable(c,matg) end,nil,sc,mg)
  if #smats==0 then return end
  Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2)) -- "소재로 포함할 '홀로판타지'를 선택"
  local smat=smats:Select(tp,1,1,nil):GetFirst()
  if not smat then return end
  -- 자신 필드 몬스터 풀(mg)로, smat을 반드시 포함하여 싱크로 소환 실행
  Duel.SynchroSummon(tp,sc,smat,mg)
end
