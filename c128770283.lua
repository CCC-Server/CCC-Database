--스펠크래프트 트리니티 마기스 (예시 이름)
local s,id=GetID()
function s.initial_effect(c)
	--링크 소환 조건: "스펠크래프트" 몬스터 2장 이상
	Link.AddProcedure(c,s.matfilter,2,99)
	c:EnableReviveLimit()

	--① 마력카운터 2개 제거 후 3가지 중 1개 선택 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DRAW+CATEGORY_RECOVER)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,{id,0})
	e1:SetHintTiming(0,TIMING_DAMAGE_STEP+TIMINGS_CHECK_MONSTER)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.operation)
	c:RegisterEffect(e1)
end

--링크 소재 필터
function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x761,lc,sumtype,tp)
end

--비용: 가마솥의 마력카운터 2개 제거
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(128770286) and c:GetCounter(0x1)>=2
end
function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_SZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	local tc=Duel.SelectMatchingCard(tp,s.cfilter,tp,LOCATION_SZONE,0,1,1,nil):GetFirst()
	if tc then
		tc:RemoveCounter(tp,0x1,2,REASON_COST)
		e:SetLabelObject(tc)
	end
end

--목표 설정: 3가지 중 선택
function s.filter(c)
	return c:IsFaceup() and c:IsSetCard(0x761) and not c:IsCode(id)
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	local opt=Duel.SelectOption(tp,
		aux.Stringid(id,1), --① 전투 파괴 방지 + 1회 데미지 0
		aux.Stringid(id,2), --② LP1000 지불 후 드로우
		aux.Stringid(id,3)) --③ LP1500 회복
	e:SetLabel(opt)
	if opt==0 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
		local g=Duel.SelectTarget(tp,s.filter,tp,LOCATION_MZONE,0,1,1,nil)
	elseif opt==1 then
		Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
	elseif opt==2 then
		Duel.SetOperationInfo(0,CATEGORY_RECOVER,nil,0,tp,1500)
	end
end

--선택 효과 처리
function s.operation(e,tp,eg,ep,ev,re,r,rp)
	local opt=e:GetLabel()
	if opt==0 then
		local tc=Duel.GetFirstTarget()
		if tc and tc:IsRelateToEffect(e) then
			--전투 파괴되지 않음
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
			e1:SetValue(1)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
			--1회 데미지 0
			local e2=Effect.CreateEffect(e:GetHandler())
			e2:SetType(EFFECT_TYPE_FIELD)
			e2:SetCode(EFFECT_CHANGE_DAMAGE)
			e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
			e2:SetTargetRange(1,0)
			e2:SetValue(s.damval)
			e2:SetReset(RESET_PHASE+PHASE_END)
			e2:SetLabelObject(tc)
			Duel.RegisterEffect(e2,tp)
		end
	elseif opt==1 then
		if Duel.CheckLPCost(tp,1000) then
			Duel.PayLPCost(tp,1000)
			Duel.Draw(tp,1,REASON_EFFECT)
		end
	elseif opt==2 then
		Duel.Recover(tp,1500,REASON_EFFECT)
	end
end

--데미지 0 처리 (한번만)
function s.damval(e,re,val,r,rp,rc)
	if not e:GetLabelObject():IsLocation(LOCATION_MZONE) then return val end
	if e:GetLabel()~=1 then
		e:SetLabel(1)
		return 0
	else
		return val
	end
end
