--파이고라 히스트라이노
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,124131233,s.pfil1)
	--①: 이 카드를 융합 소환했을 경우에 발동할 수 있다. 자신의 묘지에서 "파이고라" 몬스터 1장을 특수 소환한다. 이 턴에, 자신은 레벨을 가진 암석족 몬스터밖에 특수 소환할 수 없다.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	--자신의 메인 페이즈에 발동할 수 있다. 이 카드의 표시 형식에 따라 이하의 효과를 적용한다.
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_POSITION+CATEGORY_SPECIAL_SUMMON)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetCountLimit(1,{id,1})
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.target)
	e2:SetOperation(s.operation)
	c:RegisterEffect(e2)
end
function s.pfil1(c,lc,sumtype,tp)
	return c:IsOnField() and c:IsType(TYPE_EFFECT) and c:IsAttackPos()
end
function s.spfilter1(c,e,tp)
	return c:IsSetCard(0x822) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
	-- Cannot Special Summon from the Extra Deck, except Xyz Monsters
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:HasLevel() and c:IsRace(RACE_ROCK))
end
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x822) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return (c:IsAttackPos() and Duel.IsExistingMatchingCard(Card.IsCanChangePosition,tp,0,LOCATION_MZONE,1,nil))
			or (c:IsDefensePos() and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp))
	end
	if c:IsAttackPos() then
		local g=Duel.GetMatchingGroup(Card.IsCanChangePosition,tp,0,LOCATION_MZONE,nil)
		Duel.SetOperationInfo(0,CATEGORY_POSITION,g,#g,0,0)
	else
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,0,LOCATION_GRAVE)
	end
end
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	if c:IsAttackPos() then
		local tg=Duel.GetMatchingGroup(Card.IsCanChangePosition,tp,0,LOCATION_MZONE,nil)
		if #tg>0 and Duel.ChangePosition(tg,POS_FACEUP_DEFENSE,POS_FACEDOWN_DEFENSE,POS_FACEUP_ATTACK,POS_FACEUP_ATTACK)>0 then
			local og=Duel.GetOperatedGroup():Filter(Card.IsFaceup,nil)
			for tc in aux.Next(og) do
				local e1=Effect.CreateEffect(c)
				e1:SetDescription(3302)
				e1:SetProperty(EFFECT_FLAG_CLIENT_HINT)
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CANNOT_TRIGGER)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
				e1:SetLabel(1-tp)
				tc:RegisterEffect(e1)
			end
		end
	elseif Duel.GetLocationCount(tp,LOCATION_MZONE)>0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
		if #g>0 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
		end
	end
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
		and re:GetHandlerPlayer()==re:GetLabel()
end