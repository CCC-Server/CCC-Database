local s,id=GetID()
function s.initial_effect(c)

	---------------------------------------------------------
	-- ① 패에서 특수 소환
	---------------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,0})
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	---------------------------------------------------------
	-- ② 일반/특수 소환 성공 시 "요정향" 특수 소환
	---------------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	---------------------------------------------------------
	-- ③ 싱크로/링크 소재로 묘지로 → 되돌리고 일반 소환
	---------------------------------------------------------
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_BE_MATERIAL)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,{id,2})
	e4:SetCondition(s.nscon)
	e4:SetTarget(s.nstg)
	e4:SetOperation(s.nsop)
	c:RegisterEffect(e4)
end

---------------------------------------------------------
-- ① 패에서 특수 소환 조건
---------------------------------------------------------
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0x767)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0
		or Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

---------------------------------------------------------
-- ② 덱에서 "요정향" 특수 소환
-- (이 효과 자체에는 제약 없음 → 제약은 ③ 효과에서 부여됨)
---------------------------------------------------------
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x767) and c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end

---------------------------------------------------------
-- ③ 싱크로/링크 소재로 묘지로 보내졌을 때
-- → 요정향 1장 되돌리고, 패에서 다른 요정향 일반 소환
-- ★ 이 효과를 발동하는 턴, 요정향 싱크로/링크 몬스터만 엑덱 특소 가능
---------------------------------------------------------
function s.nscon(e,tp,eg,ep,ev,re,r,rp)
	return r&(REASON_SYNCHRO+REASON_LINK)~=0
end
function s.retfilter(c)
	return c:IsSetCard(0x767) and c:IsFaceup() and c:IsAbleToHand()
end
function s.nsfilter(c)
	return c:IsSetCard(0x767) and not c:IsCode(id) and c:IsSummonable(true,nil)
end
function s.nstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.retfilter,tp,LOCATION_ONFIELD,0,1,nil)
			and Duel.IsExistingMatchingCard(s.nsfilter,tp,LOCATION_HAND,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_ONFIELD)
	Duel.SetOperationInfo(0,CATEGORY_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.nsop(e,tp,eg,ep,ev,re,r,rp)
	-- ★ 이 턴 동안 엑덱 소환 제한 부여
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetReset(RESET_PHASE+PHASE_END)
	e1:SetTarget(s.exlimit)
	Duel.RegisterEffect(e1,tp)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g1=Duel.SelectMatchingCard(tp,s.retfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	if #g1>0 and Duel.SendtoHand(g1,nil,REASON_EFFECT)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SUMMON)
		local g2=Duel.SelectMatchingCard(tp,s.nsfilter,tp,LOCATION_HAND,0,1,1,nil)
		if #g2>0 then
			Duel.Summon(tp,g2:GetFirst(),true,nil)
		end
	end
end

-- ③ 효과용 엑스트라 제한 : 요정향 싱크로/링크만 가능
function s.exlimit(e,c,sump,sumtype,sumpos,targetp,se)
	if not c:IsLocation(LOCATION_EXTRA) then return false end
	return not (c:IsSetCard(0x767) and (c:IsType(TYPE_SYNCHRO) or c:IsType(TYPE_LINK)))
end
