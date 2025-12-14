local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 조건: 튜너 + 비튜너 "요정향" 1장 이상
	Synchro.AddProcedure(c,nil,1,1,Synchro.NonTunerEx(Card.IsSetCard,0x767),1,99)
	c:EnableReviveLimit()

	-----------------------------------------------------
	-- ①: "요정향" 특수 소환할 때마다 상대에게 300 데미지
	-----------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCondition(s.damcon)
	e1:SetOperation(s.damop)
	c:RegisterEffect(e1)

	-----------------------------------------------------
	-- ②: 배틀 페이즈 중 요정향 카드 1장 패로 → 몬스터 직접 공격
	-----------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMING_BATTLE_PHASE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.dircon)
	e2:SetOperation(s.dirop)
	c:RegisterEffect(e2)
end

-----------------------------------------------------
-- ① 효과: 자신이 "요정향" 특수 소환 시 데미지
-----------------------------------------------------
function s.damcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c) return c:IsSetCard(0x767) and c:IsSummonPlayer(tp) end,1,nil)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	local ct=eg:FilterCount(function(c) return c:IsSetCard(0x767) and c:IsSummonPlayer(tp) end,nil)
	if ct>0 then
		Duel.Damage(1-tp,ct*300,REASON_EFFECT)
	end
end

-----------------------------------------------------
-- ② 효과: 배틀 페이즈 + 카드 1장 패로 + 직접 공격
-----------------------------------------------------
function s.dircon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE
end

function s.returnfilter(c)
	return c:IsSetCard(0x767) and c:IsAbleToHand()
end

function s.directfilter(c)
	return c:IsSetCard(0x767) and c:IsFaceup()
end

function s.dirop(e,tp,eg,ep,ev,re,r,rp)
	-- Step 1: "요정향" 카드 1장 선택 → 패로 되돌림
	if not Duel.IsExistingMatchingCard(s.returnfilter,tp,LOCATION_ONFIELD,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local rg=Duel.SelectMatchingCard(tp,s.returnfilter,tp,LOCATION_ONFIELD,0,1,1,nil)
	if #rg==0 or Duel.SendtoHand(rg,nil,REASON_EFFECT)==0 then return end

	-- Step 2: 직접 공격 부여할 대상 몬스터 선택
	if not Duel.IsExistingMatchingCard(s.directfilter,tp,LOCATION_MZONE,0,1,nil) then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tg=Duel.SelectMatchingCard(tp,s.directfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local tc=tg:GetFirst()
	if tc then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DIRECT_ATTACK)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end
