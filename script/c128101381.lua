-- Fightcall Dogfight
local s,id=GetID()
function s.initial_effect(c)
	-- 카드군 표기
	-- 0xc49 = "Aero Maneuver"
	-- 0xc50 = "Fight Call"
	s.listed_series={0xc49,0xc50}

	-- 지속 함정 발동
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	-- ①: 묘지/제외존 속공 마법 3장 되돌리고 드로우 & 락
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1)
	e1:SetHintTiming(0,TIMING_MAIN_END+TIMING_END_PHASE)
	e1:SetTarget(s.tdtg)
	e1:SetOperation(s.tdop)
	c:RegisterEffect(e1)

	-- ②: 카드가 패로 되돌아갔을 경우 묘지의 "Fightcall" 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_TO_HAND)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1)
	e2:SetCondition(s.setcon)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)

	-- ③: 효과로 파괴되었을 경우 "Aeromaneuver" 소생
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_DESTROYED)
	-- 이 효과는 카드명 제약 (1턴에 1번)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

--------------------------------
-- 공통 상수
--------------------------------
local SET_AEROMANEUVER=0xc49
local SET_FIGHTCALL=0xc50

--------------------------------
-- ①번 효과 구현 (수정됨)
--------------------------------
-- 필터: 속공 마법(TYPE_QUICKPLAY)이면서 묘지 또는 제외되어 있는 카드
function s.tdfilter(c)
	return c:IsType(TYPE_QUICKPLAY) and c:IsType(TYPE_SPELL) and (c:IsLocation(LOCATION_GRAVE) or c:IsFaceup()) and c:IsAbleToDeck()
end
-- 서브 그룹 체크: 선택한 3장 중 "Fightcall" 카드가 포함되어 있는지 확인
function s.rescon(sg,e,tp,mg)
	return sg:IsExists(Card.IsSetCard,1,nil,SET_FIGHTCALL)
end

function s.tdtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	local g=Duel.GetMatchingGroup(s.tdfilter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
	
	-- 오류 수정: CheckSubGroup 대신 aux.SelectUnselectGroup 사용 (chk=0은 발동 가능 여부 확인)
	if chk==0 then 
		return aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,0) 
			and Duel.IsPlayerCanDraw(tp,1) 
	end
	
	-- 오류 수정: SelectSubGroup 대신 aux.SelectUnselectGroup 사용 (chk=1은 실제 선택)
	local sg=aux.SelectUnselectGroup(g,e,tp,3,3,s.rescon,1,tp,HINTMSG_TODECK)
	
	Duel.SetTargetCard(sg)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,sg,3,0,0)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local tg=Duel.GetTargetCards(e)
	if #tg==0 then return end
	Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	local g=Duel.GetOperatedGroup()
	if g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK+LOCATION_EXTRA) then
		if g:IsExists(Card.IsLocation,1,nil,LOCATION_DECK) then Duel.ShuffleDeck(tp) end
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
	
	-- 이 턴, 상대는 패에서 특수 소환된 몬스터의 효과를 발동할 수 없음
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_ACTIVATE)
	e1:SetTargetRange(0,1)
	e1:SetValue(s.aclimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
	-- 클라이언트 힌트 (효과 적용 중임 표시)
	aux.RegisterClientHint(c,0,tp,1,0,aux.Stringid(id,3),nil)
end

-- 효과 발동 제한 조건: 몬스터이며, 패에서 특수 소환된 상태여야 함
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return rc:IsType(TYPE_MONSTER) and rc:IsSummonLocation(LOCATION_HAND) and rc:IsSummonType(SUMMON_TYPE_SPECIAL)
end

--------------------------------
-- ②번 효과 구현
--------------------------------
-- 조건: 자신 필드의 카드가 패로 되돌아왔을 경우
function s.cfilter(c,tp)
	return c:IsPreviousControler(tp) and c:IsPreviousLocation(LOCATION_ONFIELD)
end
function s.setcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end
-- 필터: 묘지의 "Fightcall" 카드
function s.setfilter(c)
	return c:IsSetCard(SET_FIGHTCALL) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g)
	end
end

--------------------------------
-- ③번 효과 구현
--------------------------------
-- 조건: 효과로 파괴되었을 때
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end
-- 필터: 묘지의 "Aeromaneuver" 몬스터
function s.spfilter2(c,e,tp)
	return c:IsSetCard(SET_AEROMANEUVER) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end