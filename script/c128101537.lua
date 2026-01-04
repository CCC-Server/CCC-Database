--명왕의 포효
local s,id=GetID()
function s.initial_effect(c)
	--기재된 카드명: 명왕룡 반달기온
	s.listed_names={24857466}

	--①: 발동 (카운터 함정 복사)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetHintTiming(TIMINGS_CHECK_MONSTER)
	e1:SetCondition(s.condition)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	--②: 세트한 턴에 발동 가능
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_TRAP_ACT_IN_SET_TURN)
	e2:SetProperty(EFFECT_FLAG_SET_AVAILABLE)
	e2:SetCondition(s.actinsetcon)
	c:RegisterEffect(e2)
end

--[안전한 카드명 기재 확인 함수]
function s.safe_check_listed(c, target_code)
	local codes = c.listed_names
	if not codes then return false end
	for _,code in ipairs(codes) do
		if code==target_code then return true end
	end
	return false
end

--필드 조건: 명왕룡 반달기온 또는 기재된 몬스터 존재
function s.filter_vandal(c)
	return c:IsFaceup() and (c:IsCode(24857466) or s.safe_check_listed(c,24857466))
end

--복사할 카운터 함정 필터
function s.cpfilter(c,e,tp,eg,ep,ev,re,r,rp)
	return c:IsType(TYPE_COUNTER) and c:IsAbleToRemoveAsCost()
		and c:CheckActivateEffect(false,true,false)~=nil
end

--① 발동 조건
function s.condition(e,tp,eg,ep,ev,re,r,rp)
	--필드 조건 확인
	if not Duel.IsExistingMatchingCard(s.filter_vandal,tp,LOCATION_MZONE,0,1,nil) then return false end
	
	--묘지에 발동 가능한 카운터 함정이 있는지 확인
	return Duel.IsExistingMatchingCard(s.cpfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,eg,ep,ev,re,r,rp)
end

--② 세트한 턴 발동 조건 (릴리스할 몬스터가 있어야 함)
function s.actinsetcon(e)
	return Duel.IsExistingMatchingCard(s.filter_vandal,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	--세트된 턴에 발동하는 경우인지 확인 (이 효과가 세트 상태에서 발동되었고, 이번 턴에 세트됨)
	local set_turn_act = c:IsStatus(STATUS_SET_TURN) and c:IsLocation(LOCATION_SZONE) and not c:IsHasEffect(EFFECT_TRAP_ACT_IN_HAND)
	
	if chk==0 then
		--기본 코스트: 묘지 카운터 함정 제외 가능 여부
		local b1 = Duel.IsExistingMatchingCard(s.cpfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp,eg,ep,ev,re,r,rp)
		--추가 코스트: 세트 턴 발동 시 릴리스 가능 여부
		if set_turn_act then
			return b1 and Duel.CheckReleaseGroupCost(tp,s.filter_vandal,1,false,nil,nil)
		else
			return b1
		end
	end
	
	--세트 턴 발동 시 릴리스 실행
	if set_turn_act then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
		local g=Duel.SelectReleaseGroupCost(tp,s.filter_vandal,1,1,false,nil,nil)
		Duel.Release(g,REASON_COST)
	end
	
	--묘지 카운터 함정 제외 및 효과 복제 준비
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.cpfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp,eg,ep,ev,re,r,rp)
	local tc=g:GetFirst()
	local te,ceg,cep,cev,cre,cr,crp=tc:CheckActivateEffect(false,true,true)
	
	Duel.Remove(tc,POS_FACEUP,REASON_COST)
	
	--선택한 카드의 효과 속성 복사
	e:SetCategory(te:GetCategory())
	e:SetProperty(te:GetProperty())
	
	--대상 지정 등 Target 함수 실행
	local tg=te:GetTarget()
	if tg then tg(e,tp,ceg,cep,cev,cre,cr,crp,1) end
	
	--Operation 실행을 위해 라벨에 효과 저장
	te:SetLabelObject(tc)
	e:SetLabelObject(te)
	
	--명왕의 포효 발동 로그
	Duel.Hint(HINT_CARD,0,id)
	--제외한 카드(복사한 효과) 로그
	tc:CreateEffectRelation(e)
	Duel.Hint(HINT_CARD,0,tc:GetCode())
end

function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	--Cost 함수에서 Target 처리를 이미 수행하므로 여기서는 패스
	--CheckActivateEffect가 chk==0 로직을 포함함
	if chkc then return true end
	if chk==0 then return true end
end

function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local te=e:GetLabelObject()
	if not te then return end
	local op=te:GetOperation()
	if op then op(e,tp,eg,ep,ev,re,r,rp) end
end