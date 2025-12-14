local s,id=GetID()
function s.initial_effect(c)
	-- 엑시즈 소환 조건 (수왕권사 몬스터 2장)
	Xyz.AddProcedure(c,aux.FilterBoolFunction(Card.IsSetCard,0x770),2,2)
	c:EnableReviveLimit()

	-- 특수 엑시즈 소환 (회랑 위에 겹쳐 소환 가능)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	-- ① 전투 파괴 내성
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- ② 공격시 상대 몬스터 효과 봉인
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(0,1)
	e2:SetCondition(s.actcon)
	e2:SetValue(s.aclimit)
	c:RegisterEffect(e2)

	-- ③ 배틀 페이즈 중 공격력 1000 증가 (1턴 1회)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_ATKCHANGE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id)
	e3:SetCondition(s.atkcon)
	e3:SetOperation(s.atkop)
	c:RegisterEffect(e3)

	-- ④ 배틀 페이즈 종료시 "회랑" 특수 소환 + 자신 되돌림
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_PHASE+PHASE_BATTLE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id+100)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- 특수 소환 제한: "회랑" 위에 겹쳐서 엑시즈 소환 가능
function s.splimit(e,se,sp,st)
	if e:GetHandler():IsLocation(LOCATION_EXTRA) and st&SUMMON_TYPE_XYZ==SUMMON_TYPE_XYZ then
		local sc=se:GetHandler()
		return sc and sc:IsCode(128770414) -- 수왕권사-회랑 코드로 교체
	end
	return true
end

-- ② 효과 봉인 조건: 내가 공격 중일 때
function s.actcon(e)
	local c=e:GetHandler()
	return Duel.GetAttacker()==c
end
function s.aclimit(e,re,tp)
	return re:IsActiveType(TYPE_MONSTER)
end

-- ③ 공격력 상승 조건
function s.atkcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return Duel.GetTurnPlayer()==tp and (ph==PHASE_BATTLE or ph==PHASE_DAMAGE)
end
function s.atkop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and c:IsFaceup() then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
	end
end

-- ④ 회랑 특수 소환 + 자신 되돌리기
function s.filter(c,e,tp)
	return c:IsCode(12345678) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local og=c:GetOverlayGroup()
	if chk==0 then return og:IsExists(s.filter,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_MZONE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local og=c:GetOverlayGroup()
	if not c:IsRelateToEffect(e) or c:IsFacedown() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=og:FilterSelect(tp,s.filter,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if tc and Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)~=0 then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end
end
