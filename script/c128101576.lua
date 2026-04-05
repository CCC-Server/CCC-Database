-- 적막을 깎아 빚어낸 형태
local s,id=GetID()
function s.initial_effect(c)
	-- 의식 소환 조건
	c:EnableReviveLimit()
	-- 펜듈럼 프로시저
	Pendulum.AddProcedure(c)
	
	-- 세트코드 설정 (스타토치 아카데미)
	local SETCODE_STARTORCH = 0xc57
	
	-- 룰 상 "스타토치 아카데미" 카드로 취급
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(SETCODE_STARTORCH)
	c:RegisterEffect(e0)

	-- [펜듈럼 효과] ①: 자신을 의식 소환 + 묘지 회수
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.rittg)
	e1:SetOperation(s.ritop(SETCODE_STARTORCH))
	c:RegisterEffect(e1)

	-- [몬스터 효과] ①: 패에서 보여주고 P존 배치 + 덱 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.pztg(SETCODE_STARTORCH))
	e2:SetOperation(s.pzop(SETCODE_STARTORCH))
	c:RegisterEffect(e2)

	-- [몬스터 효과] ②: 프리 체인 무효화 (상대 메인 페이즈 가능)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_DISABLE+CATEGORY_REMOVE)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetRange(LOCATION_MZONE)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCountLimit(1,{id,2})
	e3:SetCondition(s.discon)
	e3:SetTarget(s.distg(SETCODE_STARTORCH))
	e3:SetOperation(s.disop)
	c:RegisterEffect(e3)
end

-- [펜듈럼 효과 ① 함수]
function s.rittg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local mg=Duel.GetRitualMaterial(tp)
		mg:RemoveCard(c)
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,false,true)
			and mg:CheckWithSumGreater(Card.GetRitualLevel,8,c)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,c,1,0,0)
end
function s.ritop(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if not c:IsRelateToEffect(e) then return end
		local mg=Duel.GetRitualMaterial(tp)
		mg:RemoveCard(c)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local mat=mg:SelectWithSumGreater(tp,Card.GetRitualLevel,8,c)
		c:SetMaterial(mat)
		Duel.Release(mat,REASON_EFFECT+REASON_RITUAL)
		Duel.BreakEffect()
		if Duel.SpecialSummon(c,SUMMON_TYPE_RITUAL,tp,tp,false,true,POS_FACEUP)>0 then
			c:CompleteProcedure()
			local g=Duel.GetMatchingGroup(aux.NecroValleyFilter(Card.IsSetCard),tp,LOCATION_GRAVE,0,nil,setcode)
			if #g>0 and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
				Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
				local sg=g:Select(tp,1,1,nil)
				Duel.SendtoHand(sg,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,sg)
			end
		end
	end
end

-- [몬스터 효과 ① 함수]
function s.desfilter(c,setcode)
	return c:IsSetCard(setcode) and c:IsMonster()
end
function s.pztg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
			and Duel.IsExistingMatchingCard(s.desfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,setcode) end
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	end
end
function s.pzop(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp)
		local c=e:GetHandler()
		if not c:IsRelateToEffect(e) or not Duel.CheckLocation(tp,LOCATION_PZONE,0) and not Duel.CheckLocation(tp,LOCATION_PZONE,1) then return end
		if Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true) then
			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
			local g=Duel.SelectMatchingCard(tp,s.desfilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,setcode)
			if #g>0 then
				Duel.Destroy(g,REASON_EFFECT)
			end
		end
	end
end

-- [몬스터 효과 ② 함수]
function s.discon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsMainPhase()
end
function s.remfilter(c,setcode)
	return c:IsSetCard(setcode) and c:IsAbleToRemove()
end
function s.distg(setcode)
	return function(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
		if chkc then return chkc:IsOnField() and chkc:IsControler(1-tp) and chkc:IsFaceup() end
		if chk==0 then return Duel.IsExistingMatchingCard(s.remfilter,tp,LOCATION_GRAVE,0,1,nil,setcode)
			and Duel.IsExistingTarget(Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,nil) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
		local g=Duel.SelectMatchingCard(tp,s.remfilter,tp,LOCATION_GRAVE,0,1,1,nil,setcode)
		Duel.Remove(g,POS_FACEUP,REASON_COST)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local tg=Duel.SelectTarget(tp,Card.IsFaceup,tp,0,LOCATION_ONFIELD,1,1,nil)
		Duel.SetOperationInfo(0,CATEGORY_DISABLE,tg,1,0,0)
	end
end
function s.disop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsFaceup() and tc:IsRelateToEffect(e) and not tc:IsDisabled() then
		local c=e:GetHandler()
		Duel.NegateRelatedChain(tc,RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e2)
	end
end