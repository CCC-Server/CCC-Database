--스크랩 그리폰
local s,id=GetID()
local CARD_SCRAP_SEARCHER=92901944
function s.initial_effect(c)
	--①: "스크랩" 몬스터가 일반 소환 / 특수 소환되었을 경우, 패에서 특수 소환
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.sumcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e1b=e1:Clone()
	e1b:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e1b)
	--①: "스크랩" 몬스터가 효과로 파괴되었을 경우 (카운트 공유)
	local e1c=e1:Clone()
	e1c:SetCode(EVENT_DESTROYED)
	e1c:SetCondition(s.descon1)
	c:RegisterEffect(e1c)
	--②: 패에서 일반 소환 / 특수 소환했을 경우, 자신 필드의 몬스터 1장을 파괴한다 (강제)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2b:SetCondition(s.handcon)
	c:RegisterEffect(e2b)
	--③: "스크랩" 카드의 효과로 파괴되어 묘지로 보내졌을 경우, "스크랩 서처"를 양쪽 필드에 각각 1장까지
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_TO_GRAVE)
	e3:SetCountLimit(1,{id,1})
	e3:SetCondition(s.sscon)
	e3:SetTarget(s.sstg)
	e3:SetOperation(s.ssop)
	c:RegisterEffect(e3)
end
s.listed_series={0x24}
s.listed_names={CARD_SCRAP_SEARCHER}

--① 조건: "스크랩" 몬스터가 소환되었을 경우 (어느 쪽 플레이어든)
function s.sumfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x24)
end
function s.sumcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.sumfilter,1,nil)
end
--① 조건: 자신이나 상대의 "스크랩" 몬스터가 효과로 파괴되었을 경우
--  필드(몬스터 존)의 "스크랩" 몬스터, 또는 패 / 덱에서 파괴된 "스크랩" 몬스터 카드
function s.desfilter1(c)
	if not c:IsReason(REASON_EFFECT) then return false end
	if c:IsPreviousLocation(LOCATION_MZONE) then
		return c:IsPreviousSetCard(0x24) or c:IsSetCard(0x24)
	end
	return c:IsPreviousLocation(LOCATION_HAND|LOCATION_DECK)
		and c:IsMonster() and c:IsSetCard(0x24)
end
function s.descon1(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.desfilter1,1,nil)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,tp,0)
	Duel.SetPossibleOperationInfo(0,CATEGORY_DESTROY,nil,1,PLAYER_ALL,LOCATION_ONFIELD)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) or Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)==0 then return end
	--그 후, 필드의 마법 / 함정 카드 1장을 파괴할 수 있다
	local g=Duel.GetMatchingGroup(Card.IsSpellTrap,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.BreakEffect()
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
		local sg=g:Select(tp,1,1,nil)
		Duel.HintSelection(sg)
		Duel.Destroy(sg,REASON_EFFECT)
	end
end

--② 패에서 특수 소환했을 경우 (일반 소환은 항상 패에서)
function s.handcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonLocation(LOCATION_HAND)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_MZONE)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	--처리 시에 고른다 (대상 지정 아님). 이 카드 자신도 고를 수 있다
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_MZONE,0,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--③ "스크랩" 카드의 효과로 파괴되어 묘지로 보내졌을 경우
function s.sscon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) and c:IsReason(REASON_EFFECT)
		and re and re:GetHandler():IsSetCard(0x24)
end
function s.ssfilter(c,e,tp,p)
	return c:IsCode(CARD_SCRAP_SEARCHER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP,p)
end
function s.canself(e,tp,g)
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and g:IsExists(s.ssfilter,1,nil,e,tp,tp)
end
function s.canopp(e,tp,g)
	return Duel.GetLocationCount(1-tp,LOCATION_MZONE,tp)>0 and g:IsExists(s.ssfilter,1,nil,e,tp,1-tp)
end
function s.sstg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_DECK|LOCATION_GRAVE,0,nil,CARD_SCRAP_SEARCHER)
	if chk==0 then return s.canself(e,tp,g) or s.canopp(e,tp,g) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK|LOCATION_GRAVE)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsCode),tp,LOCATION_DECK|LOCATION_GRAVE,0,nil,CARD_SCRAP_SEARCHER)
	local ct=0
	--자신 필드에 1장까지 (4: 자신 필드에 특수 소환하시겠습니까?)
	if s.canself(e,tp,g) and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=g:FilterSelect(tp,s.ssfilter,1,1,nil,e,tp,tp):GetFirst()
		if tc and Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
			ct=ct+1
			g:RemoveCard(tc)
		end
	end
	--상대 필드에 1장까지 (5: 상대 필드에 특수 소환하시겠습니까?)
	--"푸른 눈의 정령룡" 등 동시 특수 소환 제한이 있으면 1장만
	if not (ct>0 and Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT))
		and s.canopp(e,tp,g) and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tc=g:FilterSelect(tp,s.ssfilter,1,1,nil,e,tp,1-tp):GetFirst()
		if tc and Duel.SpecialSummonStep(tc,0,tp,1-tp,false,false,POS_FACEUP) then
			ct=ct+1
		end
	end
	Duel.SpecialSummonComplete()
end
